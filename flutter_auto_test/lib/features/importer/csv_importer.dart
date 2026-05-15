/// CSV 导入器 - 从 .csv 文件导入测试用例
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import '../../models/test_case.dart';
import '../../models/test_action.dart';

class CsvImporter {
  /// 从 CSV 文件导入测试用例
  static Future<List<TestCase>> import(File file) async {
    final content = await file.readAsString();
    final csvTable = const CsvToListConverter().convert(content);
    
    if (csvTable.isEmpty) return [];
    
    // 第一行是表头
    final header = csvTable[0] as List<dynamic>;
    final headerStrings = header.map((h) => h.toString()).toList();
    
    final testCases = <TestCase>[];
    
    // 按用例分组（同一个用例可能有多个步骤）
    TestCase? currentTestCase;
    final currentActions = <TestAction>[];
    
    for (var row = 1; row < csvTable.length; row++) {
      final rowData = csvTable[row] as List<dynamic>;
      if (rowData.isEmpty) continue;
      
      final stepStr = _getField(rowData, headerStrings, '步骤');
      if (stepStr.isEmpty) continue;
      
      final actionType = _getField(rowData, headerStrings, '操作类型');
      if (actionType.isEmpty) continue;
      
      // 获取用例信息（每行都可能包含）
      final testCaseName = _getField(rowData, headerStrings, '用例名称');
      final targetPackage = _getField(rowData, headerStrings, '目标APP包名');
      final targetAppName = _getField(rowData, headerStrings, '目标APP名称');
      
      // 如果用例名称变了，保存之前的用例
      if (testCaseName.isNotEmpty && 
          currentTestCase != null && 
          currentTestCase.name != testCaseName && 
          currentActions.isNotEmpty) {
        currentTestCase = TestCase(
          id: 'tc_${DateTime.now().millisecondsSinceEpoch}_${testCases.length}',
          name: testCaseName,
          targetAppPackage: targetPackage,
          targetAppName: targetAppName,
          actions: currentActions,
          createdAt: DateTime.now(),
        );
        testCases.add(currentTestCase);
        currentActions.clear();
      }
      
      // 创建新用例（如果是第一个或用例名称变了）
      if (currentTestCase == null || 
          (testCaseName.isNotEmpty && currentTestCase.name != testCaseName)) {
        currentTestCase = TestCase(
          id: 'tc_${DateTime.now().millisecondsSinceEpoch}_${testCases.length}',
          name: testCaseName.isNotEmpty ? testCaseName : '导入用例',
          targetAppPackage: targetPackage,
          targetAppName: targetAppName,
          actions: [],
          createdAt: DateTime.now(),
        );
      }
      
      // 解析坐标
      final x = _parseDouble(_getField(rowData, headerStrings, 'X坐标'));
      final y = _parseDouble(_getField(rowData, headerStrings, 'Y坐标'));
      final endX = _parseDouble(_getField(rowData, headerStrings, '结束X'));
      final endY = _parseDouble(_getField(rowData, headerStrings, '结束Y'));
      
      // 获取其他字段
      final text = _getField(rowData, headerStrings, '输入文本');
      final elementId = _getField(rowData, headerStrings, '元素标识');
      final waitMs = _parseInt(_getField(rowData, headerStrings, '等待(ms)'));
      final durationMs = _parseInt(_getField(rowData, headerStrings, '持续(ms)'));
      
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
      
      currentActions.add(action);
    }
    
    // 保存最后一个用例
    if (currentTestCase != null && currentActions.isNotEmpty) {
      currentTestCase = TestCase(
        id: currentTestCase!.id,
        name: currentTestCase!.name,
        targetAppPackage: currentTestCase!.targetAppPackage,
        targetAppName: currentTestCase!.targetAppName,
        actions: currentActions,
        createdAt: currentTestCase!.createdAt,
      );
      testCases.add(currentTestCase!);
    }
    
    return testCases;
  }
  
  /// 获取字段值
  static String _getField(List<dynamic> row, List<String> header, String fieldName) {
    for (var i = 0; i < header.length; i++) {
      if (header[i].contains(fieldName) && i < row.length) {
        return row[i]?.toString() ?? '';
      }
    }
    return '';
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
