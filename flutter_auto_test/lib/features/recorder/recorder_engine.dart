/// 录制引擎：通过原生无障碍服务录制操作，保存为 TestCase
/// 录制时不进行性能采集（性能采集在回放时进行）
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../models/test_action.dart';
import '../../models/test_case.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class RecorderEngine {
  static final RecorderEngine _instance = RecorderEngine._internal();
  factory RecorderEngine() => _instance;
  RecorderEngine._internal();

  final _channel = const MethodChannel('com.tencent.autotest/accessibility');
  bool _isRecording = false;
  String _currentTestCaseId = '';
  DateTime _startTime = DateTime.now();

  bool get isRecording => _isRecording;

  /// 开始录制（不需要预先知道目标包名）
  Future<void> startRecording(String testCaseId) async {
    _isRecording = true;
    _currentTestCaseId = testCaseId;
    _startTime = DateTime.now();
    await _channel.invokeMethod('startRecording');
  }

  /// 停止录制并保存用例
  Future<TestCase> stopRecording() async {
    _isRecording = false;
    final result = await _channel.invokeMethod('stopRecording');
    List<TestAction> actions = [];

    if (result is List) {
      for (var i = 0; i < result.length; i++) {
        final e = result[i];
        if (e is Map) {
          actions.add(TestAction(
            id: 'action_${i + 1}',
            actionType: e['action'] ?? 'unknown',
            x: _toDouble(e['x']),
            y: _toDouble(e['y']),
            text: e['text'],
            packageName: e['packageName'],
            className: e['className'],
            timestamp: e['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
            durationMs: null,
            screenshotPath: null,
          ));
        }
      }
    }

    final testCase = TestCase(
      id: _currentTestCaseId,
      name: '录制用例_$_currentTestCaseId',
      targetAppPackage: actions.isNotEmpty ? actions.first.packageName ?? '' : '',
      actions: actions,
      createdAt: _startTime,
      updatedAt: DateTime.now(),
    );

    await _saveTestCase(testCase);
    return testCase;
  }

  double? _toDouble(dynamic v) => v is num ? v.toDouble() : null;

  Future<void> _saveTestCase(TestCase testCase) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/test_cases/${testCase.id}.json');
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(testCase.toJson()));
  }
}
