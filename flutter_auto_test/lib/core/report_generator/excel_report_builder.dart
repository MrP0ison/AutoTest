/// Excel 报告生成器 - 生成 Excel 格式的测试报告
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/test_report.dart';
import '../../models/performance_data.dart';

class ExcelReportBuilder {
  /// 生成 Excel 报告并保存到文件
  static Future<File> build(TestReport report) async {
    final excel = Excel.createExcel();

    // 删除默认Sheet1
    excel.delete('Sheet1');

    // 创建功能测试报告Sheet
    _buildFunctionalSheet(excel, report);

    // 创建性能数据Sheet
    _buildPerformanceSheet(excel, report);

    // 保存文件
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reports/${report.id}.xlsx');
    await file.create(recursive: true);
    final bytes = excel.encode();
    await file.writeAsBytes(bytes!);
    return file;
  }

  /// 构建功能测试报告Sheet
  static void _buildFunctionalSheet(Excel excel, TestReport report) {
    final sheet = excel['功能测试报告'];

    // 标题
    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    cell.value = TextCellValue('测试报告 - ${report.testCaseName}');

    // 基本信息
    var row = 2;
    _writeInfoRow(sheet, row++, '用例名称', report.testCaseName);
    _writeInfoRow(sheet, row++, '状态', _statusText(report.status));
    _writeInfoRow(sheet, row++, '开始时间', report.startTime.toString());
    _writeInfoRow(sheet, row++, '结束时间', report.endTime?.toString() ?? '-');
    _writeInfoRow(sheet, row++, '通过率', '${report.passRate?.toStringAsFixed(1) ?? "-"}%');

    if (report.failureReason != null) {
      _writeInfoRow(sheet, row++, '失败原因', report.failureReason!);
    }

    // 步骤详情表头
    row += 2;
    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue('步骤');

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    cell.value = TextCellValue('状态');

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
    cell.value = TextCellValue('错误信息');

    // 步骤详情数据
    for (var i = 0; i < report.stepResults.length; i++) {
      final result = report.stepResults[i];
      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue('第 ${i + 1} 步');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue(result.passed ? '通过' : '失败');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value =
          TextCellValue(result.errorMsg ?? '-');
    }
  }

  /// 构建性能数据Sheet
  static void _buildPerformanceSheet(Excel excel, TestReport report) {
    if (report.performanceData.isEmpty) return;

    final sheet = excel['性能数据'];

    // 表头
    final headers = [
      '时间戳',
      'CPU(%)',
      '内存(KB)',
      'FPS',
      '功耗(mW)',
      '电流(mA)',
      '耗电(mAh)',
      '网络发送(KB)',
      '网络接收(KB)',
      '网络类型',
    ];

    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
    }

    // 数据行
    for (var i = 0; i < report.performanceData.length; i++) {
      final data = report.performanceData[i];
      var col = 0;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: i + 1)).value =
          TextCellValue(DateTime.fromMillisecondsSinceEpoch(data.timestamp).toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: i + 1)).value =
          TextCellValue(data.cpuUsage?.toStringAsFixed(1) ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: i + 1)).value =
          TextCellValue(data.memoryPssKb?.toString() ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: i + 1)).value =
          TextCellValue(data.fps?.toStringAsFixed(1) ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: i + 1)).value =
          TextCellValue(data.powerMw?.toStringAsFixed(1) ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: i + 1)).value =
          TextCellValue(data.batteryCurrentMa?.toStringAsFixed(1) ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: i + 1)).value =
          TextCellValue(data.batteryMah?.toString() ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: i + 1)).value =
          TextCellValue(data.networkSentKb?.toString() ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: i + 1)).value =
          TextCellValue(data.networkRecvKb?.toString() ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col++, rowIndex: i + 1)).value =
          TextCellValue(data.networkType ?? '-');
    }
  }

  /// 写入信息行
  static void _writeInfoRow(Sheet sheet, int row, String label, String value) {
    var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
    cell.value = TextCellValue(label);

    cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
    cell.value = TextCellValue(value);
  }

  /// 状态文本
  static String _statusText(TestStatus status) {
    switch (status) {
      case TestStatus.passed:
        return '通过';
      case TestStatus.failed:
        return '失败';
      case TestStatus.running:
        return '执行中';
      case TestStatus.stopped:
        return '已停止';
      default:
        return '等待中';
    }
  }
}
