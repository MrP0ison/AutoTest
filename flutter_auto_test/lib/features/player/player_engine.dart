/// 用例回放引擎 - 解析 TestCase，按顺序执行操作
/// 同时采集性能数据，并生成文字报告
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/test_case.dart';
import '../../models/test_action.dart';
import '../../models/test_report.dart';
import '../../models/performance_data.dart';
import '../../core/performance_monitor/performance_monitor.dart';
import '../../core/report_generator/report_generator.dart';

/// 回放进度回调
typedef ProgressCallback = void Function(int currentStep, int totalSteps, String currentAction);

class PlayerEngine {
  static final PlayerEngine _instance = PlayerEngine._internal();
  factory PlayerEngine() => _instance;
  PlayerEngine._internal();

  final _channel = const MethodChannel('com.tencent.autotest/accessibility');
  final _perf = PerformanceMonitor();
  final _reportGen = ReportGenerator();
  final List<StepResult> _stepResults = [];

  TestReport? _currentReport;
  
  /// 进度回调
  ProgressCallback? onProgress;

  Future<TestReport> execute(TestCase testCase) async {
    _stepResults.clear();

    _currentReport = TestReport(
      id: 'report_${DateTime.now().millisecondsSinceEpoch}',
      testCaseId: testCase.id,
      testCaseName: testCase.name,
      startTime: DateTime.now(),
      status: TestStatus.running,
      stepResults: _stepResults,
      performanceData: [],
    );

    _perf.start(_currentReport!.id, testCase.targetAppPackage);

    for (var i = 0; i < testCase.actions.length; i++) {
      final action = testCase.actions[i];
      
      // 回调进度
      onProgress?.call(i + 1, testCase.actions.length, action.actionType);
      
      final result = await _executeAction(action, i);
      _stepResults.add(result);
      
      if (!result.passed) {
        _currentReport!.status = TestStatus.failed;
        _currentReport!.failureReason = result.errorMsg;
        break;
      }
    }

    if (_currentReport!.status == TestStatus.running) {
      _currentReport!.status = TestStatus.passed;
    }

    _perf.stop();
    _currentReport!.performanceData = List<PerformanceData>.from(_perf.data);
    _currentReport!.endTime = DateTime.now();

    // 保存 JSON 报告
    await _saveJsonReport(_currentReport!);

    // 生成并保存文字报告
    await _saveTextReports(_currentReport!);

    return _currentReport!;
  }

  Future<StepResult> _executeAction(TestAction action, int index) async {
    try {
      switch (action.actionType) {
        case 'click':
          return _executeClick(action, index);
        case 'long_click':
          return _executeLongClick(action, index);
        case 'input':
          return _executeInput(action, index);
        case 'swipe':
          return _executeSwipe(action, index);
        case 'back':
          return _executeBack(index);
        default:
          return StepResult(
            actionId: action.id,
            stepIndex: index,
            passed: false,
            errorMsg: '未知操作类型: ${action.actionType}',
          );
      }
    } catch (e) {
      return StepResult(
        actionId: action.id,
        stepIndex: index,
        passed: false,
        errorMsg: e.toString(),
      );
    }
  }

  Future<StepResult> _executeClick(TestAction action, int index) async {
    final result = await _channel.invokeMethod('performClick', {
      'x': action.x ?? 0.0,
      'y': action.y ?? 0.0,
    });
    return StepResult(
      actionId: action.id,
      stepIndex: index,
      passed: result == true,
      errorMsg: result == true ? null : '点击失败',
    );
  }

  Future<StepResult> _executeLongClick(TestAction action, int index) async {
    final result = await _channel.invokeMethod('performLongClick', {
      'x': action.x ?? 0.0,
      'y': action.y ?? 0.0,
      'durationMs': action.durationMs ?? 800,
    });
    return StepResult(
      actionId: action.id,
      stepIndex: index,
      passed: result == true,
      errorMsg: result == true ? null : '长按失败',
    );
  }

  Future<StepResult> _executeInput(TestAction action, int index) async {
    if (action.text == null) {
      return StepResult(
        actionId: action.id,
        stepIndex: index,
        passed: false,
        errorMsg: '输入操作缺少 text 参数',
      );
    }
    final result = await _channel.invokeMethod('performInput', {
      'text': action.text,
    });
    return StepResult(
      actionId: action.id,
      stepIndex: index,
      passed: result == true,
      errorMsg: result == true ? null : '输入失败',
    );
  }

  Future<StepResult> _executeSwipe(TestAction action, int index) async {
    final result = await _channel.invokeMethod('performSwipe', {
      'x1': action.x ?? 0.0,
      'y1': action.y ?? 0.0,
      'x2': action.endX ?? 0.0,
      'y2': action.endY ?? 0.0,
    });
    return StepResult(
      actionId: action.id,
      stepIndex: index,
      passed: result == true,
      errorMsg: result == true ? null : '滑动失败',
    );
  }

  Future<StepResult> _executeBack(int index) async {
    final result = await _channel.invokeMethod('performBack', {});
    return StepResult(
      actionId: 'back_$index',
      stepIndex: index,
      passed: result == true,
      errorMsg: result == true ? null : '返回失败',
    );
  }

  Future<void> _saveJsonReport(TestReport report) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reports/${report.id}.json');
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(report.toJson()));
  }

  Future<void> _saveTextReports(TestReport report) async {
    try {
      // 功能报告
      final functionalText = await _reportGen.generateFunctionalReport(report);
      final funcFile = File('${(await getApplicationDocumentsDirectory()).path}/reports/${report.id}_functional.txt');
      await funcFile.create(recursive: true);
      await funcFile.writeAsString(functionalText);

      // 性能报告（读取预期指标）
      final prefs = await SharedPreferences.getInstance();
      final expected = <String, dynamic>{
        'maxCpu': double.tryParse(prefs.getString('expected_cpu') ?? '80') ?? 80.0,
        'maxMemoryMb': int.tryParse(prefs.getString('expected_memory_mb') ?? '512') ?? 512,
        'minFps': double.tryParse(prefs.getString('expected_min_fps') ?? '30') ?? 30.0,
        'maxPowerMw': double.tryParse(prefs.getString('expected_max_power_mw') ?? '2000') ?? 2000.0,
        'maxBatteryCurrentMa': double.tryParse(prefs.getString('expected_max_current_ma') ?? '500') ?? 500.0,
        'maxBatteryMah': int.tryParse(prefs.getString('expected_max_sent_kb') ?? '10240') ?? 10240,
        'maxNetworkSentKb': int.tryParse(prefs.getString('expected_max_sent_kb') ?? '10240') ?? 10240,
        'maxNetworkRecvKb': int.tryParse(prefs.getString('expected_max_recv_kb') ?? '10240') ?? 10240,
      };
      final perfText = await _reportGen.generatePerformanceReport(report, expected);
      final perfFile = File('${(await getApplicationDocumentsDirectory()).path}/reports/${report.id}_performance.txt');
      await perfFile.create(recursive: true);
      await perfFile.writeAsString(perfText);
    } catch (e) {
      print('保存文字报告失败: $e');
    }
  }
}
