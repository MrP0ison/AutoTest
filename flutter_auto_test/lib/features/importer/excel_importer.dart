/// Excel 导入器 - 从 .xlsx 文件导入测试用例
import 'dart:io';
import 'package:excel/excel.dart';
import '../../models/test_case.dart';
import '../../models/test_action.dart';

class ExcelImporter {
  /// 从 Excel 文件导入测试用例
  /// 返回 TestCase 列表（一个Excel文件可能包含多个用例）
  static Future<List<TestCase>> import(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    
    final testCases = <TestCase>[];
    
    // 遍历所有Sheet
    for (final sheetName in excel.tables.keys) {
      final sheet = excel.tables[sheetName]!;
      final testCase = _parseSheet(sheet, sheetName);
      if (testCase != null) {
        testCases.add(testCase);
      }
    }
    
    return testCases;
  }
  
  /// 解析单个Sheet为TestCase
  static TestCase? _parseSheet(Sheet sheet, String sheetName) {
    if (sheet.maxRows < 2) return null;
    
    // 第一行是表头
    final header = <String>[];
    for (var col = 0; col < sheet.maxColumns; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      final value = cell.value?.toString() ?? '';
      header.add(value);
    }
    
    // 解析用例基本信息（从第二行开始是步骤）
    var testCaseName = sheetName;
    var targetPackage = '';
    var targetAppName = '';
    final actions = <TestAction>[];
    
    // 从第二行开始解析步骤
    for (var row = 1; row < sheet.maxRows; row++) {
      final stepStr = _getCellValue(sheet, row, _getColumnIndex(header, '步骤'));
      if (stepStr.isEmpty) continue;
      
      final actionType = _getCellValue(sheet, row, _getColumnIndex(header, '操作类型'));
      if (actionType.isEmpty) continue;
      
      // 获取坐标
      final x = _parseDouble(_getCellValue(sheet, row, _getColumnIndex(header, 'X坐标')));
      final y = _parseDouble(_getCellValue(sheet, row, _getColumnIndex(header, 'Y坐标')));
      final endX = _parseDouble(_getCellValue(sheet, row, _getColumnIndex(header, '结束X')));
      final endY = _parseDouble(_getCellValue(sheet, row, _getColumnIndex(header, '结束Y')));
      
      // 获取其他字段
      final text = _getCellValue(sheet, row, _getColumnIndex(header, '输入文本'));
      final elementId = _getCellValue(sheet, row, _getColumnIndex(header, '元素标识'));
      final waitMs = _parseInt(_getCellValue(sheet, row, _getColumnIndex(header, '等待(ms)')));
      final durationMs = _parseInt(_getCellValue(sheet, row, _getColumnIndex(header, '持续(ms)')));
      
      // 如果是第一行，尝试获取用例信息
      if (row == 1) {
        testCaseName = _getCellValue(sheet, row, _getColumnIndex(header, '用例名称'));
        if (testCaseName.isEmpty) testCaseName = sheetName;
        
        targetPackage = _getCellValue(sheet, row, _getColumnIndex(header, '目标APP包名'));
        targetAppName = _getCellValue(sheet, row, _getColumnIndex(header, '目标APP名称'));
      }
      
      final action = TestAction(
        id: 'action_$stepStr',
        actionType: actionType,
        x: x,
        y: y,
        endX: endX,
        endY: endY,
        text: text.isEmpty ? null : text,
        elementId: elementId.isEmpty ? null : elementId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        durationMs: durationMs,
      );
      
      actions.add(action);
    }
    
    if (actions.isEmpty) return null;
    
    return TestCase(
      id: 'tc_${DateTime.now().millisecondsSinceEpoch}',
      name: testCaseName,
      targetAppPackage: targetPackage,
      targetAppName: targetAppName,
      actions: actions,
      createdAt: DateTime.now(),
    );
  }
  
  /// 获取单元格值
  static String _getCellValue(Sheet sheet, int row, int col) {
    if (col < 0 || col >= sheet.maxColumns) return '';
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    return cell.value?.toString() ?? '';
  }
  
  /// 获取列索引
  static int _getColumnIndex(List<String> header, String columnName) {
    for (var i = 0; i < header.length; i++) {
      if (header[i].contains(columnName)) return i;
    }
    return -1;
  }
  
  /// 解析 double
  static double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }
  
  /// 解析 int
  static int? _parseInt(String value) {
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }
}
