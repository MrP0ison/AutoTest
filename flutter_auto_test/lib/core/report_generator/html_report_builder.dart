/// HTML 报告生成器 - 生成带样式的 HTML 测试报告
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/test_report.dart';
import '../../models/performance_data.dart';

class HtmlReportBuilder {
  /// 生成 HTML 报告并保存到文件
  static Future<File> build(TestReport report) async {
    final html = _generateHtml(report);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reports/${report.id}.html');
    await file.create(recursive: true);
    await file.writeAsString(html);
    return file;
  }

  /// 生成 HTML 字符串
  static String _generateHtml(TestReport report) {
    final buffer = StringBuffer();
    
    // HTML 头部
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="zh-CN">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln('  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>测试报告 - ${report.testCaseName}</title>');
    buffer.writeln('  <style>');
    buffer.writeln('    body { font-family: "Microsoft YaHei", Arial, sans-serif; margin: 20px; background: #f5f5f5; }');
    buffer.writeln('    .container { max-width: 100px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }');
    buffer.writeln('    h1 { color: #333; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }');
    buffer.writeln('    .info { background: #f9f9f9; padding: 15px; border-radius: 5px; margin: 15px 0; }');
    buffer.writeln('    .info-row { display: flex; margin: 8px 0; }');
    buffer.writeln('    .info-label { font-weight: bold; width: 120px; color: #666; }');
    buffer.writeln('    .status-pass { color: #4CAF50; font-weight: bold; }');
    buffer.writeln('    .status-fail { color: #f44336; font-weight: bold; }');
    buffer.writeln('    table { width: 100%; border-collapse: collapse; margin: 15px 0; }');
    buffer.writeln('    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }');
    buffer.writeln('    th { background: #4CAF50; color: white; }');
    buffer.writeln('    .step-pass { color: #4CAF50; }');
    buffer.writeln('    .step-fail { color: #f44336; }');
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    
    // 报告内容
    buffer.writeln('  <div class="container">');
    buffer.writeln('    <h1>测试报告</h1>');
    
    // 基本信息
    buffer.writeln('    <div class="info">');
    buffer.writeln('      <div class="info-row">');
    buffer.writeln('        <span class="info-label">用例名称：</span>');
    buffer.writeln('        <span>${report.testCaseName}</span>');
    buffer.writeln('      </div>');
    buffer.writeln('      <div class="info-row">');
    buffer.writeln('        <span class="info-label">状态：</span>');
    buffer.writeln('        <span class="${report.status == TestStatus.passed ? "status-pass" : "status-fail"}">${_statusText(report.status)}</span>');
    buffer.writeln('      </div>');
    buffer.writeln('      <div class="info-row">');
    buffer.writeln('        <span class="info-label">开始时间：</span>');
    buffer.writeln('        <span>${report.startTime}</span>');
    buffer.writeln('      </div>');
    buffer.writeln('      <div class="info-row">');
    buffer.writeln('        <span class="info-label">结束时间：</span>');
    buffer.writeln('        <span>${report.endTime ?? "-"}</span>');
    buffer.writeln('      </div>');
    buffer.writeln('      <div class="info-row">');
    buffer.writeln('        <span class="info-label">通过率：</span>');
    buffer.writeln('        <span>${report.passRate?.toStringAsFixed(1) ?? "-"}%</span>');
    buffer.writeln('      </div>');
    if (report.failureReason != null) {
      buffer.writeln('      <div class="info-row">');
      buffer.writeln('        <span class="info-label">失败原因：</span>');
      buffer.writeln('        <span class="status-fail">${report.failureReason}</span>');
      buffer.writeln('      </div>');
    }
    buffer.writeln('    </div>');
    
    // 步骤详情
    buffer.writeln('    <h2>步骤详情</h2>');
    buffer.writeln('    <table>');
    buffer.writeln('      <tr>');
    buffer.writeln('        <th>步骤</th>');
    buffer.writeln('        <th>状态</th>');
    buffer.writeln('        <th>错误信息</th>');
    buffer.writeln('      </tr>');
    
    for (final result in report.stepResults) {
      final statusClass = result.passed ? 'step-pass' : 'step-fail';
      final statusText = result.passed ? '通过' : '失败';
      buffer.writeln('      <tr>');
      buffer.writeln('        <td>第 ${result.stepIndex + 1} 步</td>');
      buffer.writeln('        <td class="$statusClass">$statusText</td>');
      buffer.writeln('        <td>${result.errorMsg ?? "-"}</td>');
      buffer.writeln('      </tr>');
    }
    
    buffer.writeln('    </table>');
    buffer.writeln('  </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    
    return buffer.toString();
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
