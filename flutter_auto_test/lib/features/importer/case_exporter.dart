/// 用例导出器 - 将测试用例导出为 Excel/CSV/JSON 格式
import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart';
import '../../models/test_case.dart';
import '../../models/test_action.dart';

class CaseExporter {
  /// 导出为 Excel 文件
  static Future<File> exportToExcel(TestCase testCase, String outputPath) async {
    final excel = Excel.createExcel();
    
    // 删除默认Sheet1
    excel.delete('Sheet1');
    
    // 创建用例工作表
    final sheet = excel['测试用例'];
    
    // 表头
    final header = [
      '用例名称',
      '目标APP包名',
      '目标APP名称',
      '步骤',
      '操作类型',
      'X坐标',
      'Y坐标',
      '结束X',
      '结束Y',
      '输入文本',
      '元素标识',
      '等待(ms)',
      '持续(ms)',
      '备注',
    ];
    
    for (var col = 0; col < header.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: 0,
      ));
      cell.value = TextCellValue(header[col]);
    }
    
    // 写入步骤
    for (var i = 0; i < testCase.actions.length; i++) {
      final action = testCase.actions[i];
      final rowData = [
        TextCellValue(testCase.name),
        TextCellValue(testCase.targetAppPackage),
        TextCellValue(testCase.targetAppName),
        TextCellValue((i + 1).toString()),
        TextCellValue(action.actionType),
        TextCellValue(action.x?.toString() ?? ''),
        TextCellValue(action.y?.toString() ?? ''),
        TextCellValue(action.endX?.toString() ?? ''),
        TextCellValue(action.endY?.toString() ?? ''),
        TextCellValue(action.text ?? ''),
        TextCellValue(action.elementId ?? ''),
        TextCellValue(''),
        TextCellValue(action.durationMs?.toString() ?? ''),
        TextCellValue(''),
      ];
      
      for (var col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: col,
          rowIndex: i + 1,
        ));
        cell.value = rowData[col];
      }
    }
    
    // 保存文件
    final fileBytes = excel.encode();
    final file = File(outputPath);
    await file.writeAsBytes(fileBytes!);
    return file;
  }
  
  /// 导出为 CSV 文件
  static Future<File> exportToCsv(TestCase testCase, String outputPath) async {
    final buffer = StringBuffer();
    
    // 表头
    buffer.writeln(
        '用例名称,目标APP包名,目标APP名称,步骤,操作类型,X坐标,Y坐标,结束X,结束Y,输入文本,元素标识,等待(ms),持续(ms),备注');
    
    // 写入步骤
    for (var i = 0; i < testCase.actions.length; i++) {
      final action = testCase.actions[i];
      buffer.writeln(
        '${testCase.name},'
        '${testCase.targetAppPackage},'
        '${testCase.targetAppName},'
        '${(i + 1)},'
        '${action.actionType},'
        '${action.x ?? ""},'
        '${action.y ?? ""},'
        '${action.endX ?? ""},'
        '${action.endY ?? ""},'
        '${action.text ?? ""},'
        '${action.elementId ?? ""},'
        ','
        '${action.durationMs ?? ""},'
        '',
      );
    }
    
    final file = File(outputPath);
    await file.writeAsString(buffer.toString());
    return file;
  }
  
  /// 导出为 JSON 文件
  static Future<File> exportToJson(TestCase testCase, String outputPath) async {
    final json = testCase.toJson();
    final jsonString = jsonEncode(json);
    
    final file = File(outputPath);
    await file.writeAsString(jsonString);
    return file;
  }
}
