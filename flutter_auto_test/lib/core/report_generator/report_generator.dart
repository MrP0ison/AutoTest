/// 测试报告生成器 - 输出功能报告、性能报告（支持 CSV / TXT）
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/performance_data.dart';
import '../../models/test_report.dart';

class ReportGenerator {
  static final ReportGenerator _instance = ReportGenerator._internal();
  factory ReportGenerator() => _instance;
  ReportGenerator._internal();

  /// 生成功能测试报告（文本格式）
  Future<String> generateFunctionalReport(TestReport report) async {
    final buf = StringBuffer();
    buf.writeln('=== 功能测试报告 ===');
    buf.writeln('用例: ${report.testCaseName}');
    buf.writeln('状态: ${_statusText(report.status)}');
    buf.writeln('开始: ${report.startTime}');
    buf.writeln('结束: ${report.endTime}');
    final durationSec = report.duration?.inSeconds ?? 0;
    buf.writeln('耗时: ${durationSec}秒');
    final passRate = report.passRate;
    buf.writeln('通过率: ${passRate != null ? passRate.toStringAsFixed(1) : "-"}%');
    if (report.failureReason != null) {
      buf.writeln('失败原因: ${report.failureReason}');
    }
    buf.writeln('');
    buf.writeln('--- 步骤详情 ---');
    for (final r in report.stepResults) {
      final status = r.passed ? "OK" : "FAIL";
      buf.writeln('[步骤 ${r.stepIndex + 1}] $status  ${r.errorMsg ?? ""}');
    }
    return buf.toString();
  }

  /// 生成性能测试报告（含与预期指标对比）
  Future<String> generatePerformanceReport(
    TestReport report,
    Map<String, dynamic>? expected,
  ) async {
    final buf = StringBuffer();
    buf.writeln('=== 性能测试报告 ===');
    buf.writeln('用例: ${report.testCaseName}');
    buf.writeln('采集数据点: ${report.performanceData.length}');
    buf.writeln('');

    if (expected != null) {
      buf.writeln('--- 预期指标对比 ---');
      _addCpuSection(buf, report, expected);
      _addMemorySection(buf, report, expected);
      _addFpsSection(buf, report, expected);
      _addPowerSection(buf, report, expected);
      _addBatterySection(buf, report, expected);
      _addNetworkSection(buf, report, expected);
    } else {
      buf.writeln('(未配置预期指标，仅展示采集数据)');
      _addAllRaw(buf, report);
    }
    return buf.toString();
  }

  void _addCpuSection(StringBuffer buf, TestReport r, Map<String, dynamic> e) {
    final values = r.performanceData.where((d) => d.cpuUsage != null).map((d) => d.cpuUsage!).toList();
    if (values.isEmpty) return;
    final max = values.reduce((a, b) => a > b ? a : b);
    final maxExpected = (e['maxCpu'] ?? 80).toDouble();
    buf.writeln('CPU(%): 最高=${max.toStringAsFixed(1)}  预期<${maxExpected.toStringAsFixed(1)}  ${max > maxExpected ? "❌ 超标" : "✓ 正常"}');
  }

  void _addMemorySection(StringBuffer buf, TestReport r, Map<String, dynamic> e) {
    final values = r.performanceData.where((d) => d.memoryPssKb != null).map((d) => d.memoryPssKb! ~/ 1024).toList();
    if (values.isEmpty) return;
    final max = values.reduce((a, b) => a > b ? a : b);
    final maxExpected = (e['maxMemoryMb'] ?? 512).toInt();
    buf.writeln('内存(MB): 最高=${max}  预期<${maxExpected}  ${max > maxExpected ? "❌ 超标" : "✓ 正常"}');
  }

  void _addFpsSection(StringBuffer buf, TestReport r, Map<String, dynamic> e) {
    final values = r.performanceData.where((d) => d.fps != null).map((d) => d.fps!).toList();
    if (values.isEmpty) return;
    final minFps = values.reduce((a, b) => a < b ? a : b);
    final minExpected = (e['minFps'] ?? 30).toDouble();
    buf.writeln('FPS: 最低=${minFps.toStringAsFixed(1)}  预期>${minExpected.toStringAsFixed(1)}  ${minFps < minExpected ? "❌ 超标" : "✓ 正常"}');
  }

  /// 功耗指标对比
  void _addPowerSection(StringBuffer buf, TestReport r, Map<String, dynamic> e) {
    final powerValues = r.performanceData.where((d) => d.powerMw != null).map((d) => d.powerMw!).toList();
    final currentValues = r.performanceData.where((d) => d.batteryCurrentMa != null).map((d) => d.batteryCurrentMa!).toList();
    if (powerValues.isEmpty && currentValues.isEmpty) return;

    buf.writeln('--- 功耗指标 ---');
    if (powerValues.isNotEmpty) {
      final maxPower = powerValues.reduce((a, b) => a > b ? a : b);
      final maxExpected = (e['maxPowerMw'] ?? 2000).toDouble();
      buf.writeln('  功耗(mW): 最高=${maxPower.toStringAsFixed(1)}  预期<${maxExpected.toStringAsFixed(1)}  ${maxPower > maxExpected ? "❌ 超标" : "✓ 正常"}');
    }
    if (currentValues.isNotEmpty) {
      final maxCurrent = currentValues.reduce((a, b) => a > b ? a : b);
      final maxExpected = (e['maxBatteryCurrentMa'] ?? 500).toDouble();
      buf.writeln('  电流(mA): 最高=${maxCurrent.toStringAsFixed(1)}  预期<${maxExpected.toStringAsFixed(1)}  ${maxCurrent > maxExpected ? "❌ 超标" : "✓ 正常"}');
    }
  }

  /// 电池累计耗电
  void _addBatterySection(StringBuffer buf, TestReport r, Map<String, dynamic> e) {
    final mahValues = r.performanceData.where((d) => d.batteryMah != null).map((d) => d.batteryMah!).cast<int>().toList();
    if (mahValues.isEmpty) return;
    final lastMah = mahValues.last;
    final maxExpected = e['maxBatteryMah'] ?? 100;
    buf.writeln('  累计耗电(mAh): ${lastMah}  预期<${maxExpected}  ${lastMah > maxExpected ? "❌ 超标" : "✓ 正常"}');
  }

  /// 网络指标对比
  void _addNetworkSection(StringBuffer buf, TestReport r, Map<String, dynamic> e) {
    final sentValues = r.performanceData.where((d) => d.networkSentKb != null).map((d) => d.networkSentKb!).cast<int>().toList();
    final recvValues = r.performanceData.where((d) => d.networkRecvKb != null).map((d) => d.networkRecvKb!).cast<int>().toList();
    final types = r.performanceData.where((d) => d.networkType != null).map((d) => d.networkType!).toSet();
    if (sentValues.isEmpty && recvValues.isEmpty) return;

    buf.writeln('--- 网络指标 ---');
    if (sentValues.isNotEmpty) {
      final totalSent = sentValues.reduce((a, b) => a + b);
      final maxExpected = e['maxNetworkSentKb'] ?? 10240;
      buf.writeln('  总发送(KB): ${totalSent}  预期<${maxExpected}  ${totalSent > maxExpected ? "❌ 超标" : "✓ 正常"}');
    }
    if (recvValues.isNotEmpty) {
      final totalRecv = recvValues.reduce((a, b) => a + b);
      final maxExpected = e['maxNetworkRecvKb'] ?? 10240;
      buf.writeln('  总接收(KB): ${totalRecv}  预期<${maxExpected}  ${totalRecv > maxExpected ? "❌ 超标" : "✓ 正常"}');
    }
    if (types.isNotEmpty) {
      buf.writeln('  网络类型: ${types.join("/")}');
    }
  }

  void _addAllRaw(StringBuffer buf, TestReport r) {
    buf.writeln('');
    buf.writeln('--- 全部采集数据 ---');
    for (final d in r.performanceData) {
      buf.writeln('[${DateTime.fromMillisecondsSinceEpoch(d.timestamp)}] '
          'CPU=${d.cpuUsage?.toStringAsFixed(1) ?? "-"}% '
          'Mem=${d.memoryPssKb != null ? (d.memoryPssKb! ~/ 1024).toString() : "-"}MB '
          'FPS=${d.fps?.toStringAsFixed(1) ?? "-"} '
          'Power=${d.powerMw?.toStringAsFixed(1) ?? "-"}mW '
          'Current=${d.batteryCurrentMa?.toStringAsFixed(1) ?? "-"}mA '
          'Sent=${d.networkSentKb ?? "-"}KB Recv=${d.networkRecvKb ?? "-"}KB');
    }
  }

  /// 导出为 CSV 文件
  Future<File> exportCsv(TestReport report) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reports/${report.id}.csv');
    await file.create(recursive: true);
    final buf = StringBuffer();
    buf.writeln('timestamp,cpu_usage_pct,memory_pss_kb,fps,power_mw,battery_current_ma,battery_mah,network_sent_kb,network_recv_kb,network_type');
    for (final d in report.performanceData) {
      buf.writeln('${d.timestamp},'
          '${d.cpuUsage ?? ""},${d.memoryPssKb ?? ""},${d.fps ?? ""},'
          '${d.powerMw ?? ""},${d.batteryCurrentMa ?? ""},${d.batteryMah ?? ""},'
          '${d.networkSentKb ?? ""},${d.networkRecvKb ?? ""},"${d.networkType ?? ""}"');
    }
    await file.writeAsString(buf.toString());
    return file;
  }

  /// 保存文字报告到本地
  Future<File> saveReport(TestReport report) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reports/${report.id}.txt');
    await file.create(recursive: true);
    final content = await generateFunctionalReport(report);
    await file.writeAsString(content);
    return file;
  }

  String _statusText(TestStatus s) => switch (s) {
        TestStatus.passed => '通过',
        TestStatus.failed => '失败',
        TestStatus.running => '执行中',
        TestStatus.stopped => '已停止',
        _ => '等待中',
      };
}
