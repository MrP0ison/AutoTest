/// 录制引擎：通过原生无障碍服务录制操作，保存为 TestCase
/// 录制时不进行性能采集（性能采集在回放时进行）
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/test_action.dart';
import '../../models/test_case.dart';

class RecorderEngine {
  static final RecorderEngine _instance = RecorderEngine._internal();
  factory RecorderEngine() => _instance;
  RecorderEngine._internal();

  final _channel = const MethodChannel('com.tencent.autotest/accessibility');
  bool _isRecording = false;
  String _currentTestCaseId = '';
  DateTime _startTime = DateTime.now();

  bool get isRecording => _isRecording;

  /// 开始录制（不需要预先知道目标包名，从事件自动提取）
  Future<void> startRecording(String testCaseId) async {
    _currentTestCaseId = testCaseId;
    _startTime = DateTime.now();
    _isRecording = true;
    await _channel.invokeMethod('startRecording');
  }

  /// 停止录制并保存用例
  /// 返回保存后的 TestCase
  Future<TestCase> stopRecording() async {
    _isRecording = false;
    final result = await _channel.invokeMethod('stopRecording');

    if (result == null) {
      throw Exception('录制失败：无法获取录制事件');
    }

    final actionList = result as List<dynamic>;
    final actions = <TestAction>[];

    // 按时间排序事件
    actionList.sort((a, b) {
      final ta = a['timestamp'] ?? 0;
      final tb = b['timestamp'] ?? 0;
      return ta.compareTo(tb);
    });

    for (final e in actionList) {
      final action = _convertEventToAction(e as Map<dynamic, dynamic>);
      if (action != null) {
        actions.add(action);
      }
    }

    if (actions.isEmpty) {
      throw Exception('录制失败：没有可转换的操作');
    }

    // 从第一个动作提取目标APP包名
    final targetPackage = actions.isNotEmpty && actions.first.packageName != null
        ? actions.first.packageName!
        : '';

    final testCase = TestCase(
      id: _currentTestCaseId,
      name: '录制用例_$_currentTestCaseId',
      description: '自动录制的测试用例',
      targetAppPackage: targetPackage,
      targetAppName: '',
      actions: actions,
      createdAt: _startTime,
      updatedAt: DateTime.now(),
    );

    await _saveTestCase(testCase);

    return testCase;
  }

  /// 将原生事件转换为 TestAction
  TestAction? _convertEventToAction(Map<dynamic, dynamic> e) {
    final actionType = e['action'] as String? ?? 'unknown';
    final x = _toDouble(e['x']);
    final y = _toDouble(e['y']);
    final text = e['text'] as String?;
    final pkg = e['packageName'] as String? ?? '';
    final className = e['className'] as String? ?? '';
    final timestamp = e['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    switch (actionType) {
      case 'click':
        // 点击必须有坐标
        if (x != null && y != null && x > 0 && y > 0) {
          return TestAction(
            id: 'action_$timestamp',
            actionType: 'click',
            x: x,
            y: y,
            packageName: pkg,
            className: className,
            timestamp: timestamp,
          );
        }
        return null;

      case 'long_click':
        if (x != null && y != null && x > 0 && y > 0) {
          return TestAction(
            id: 'action_$timestamp',
            actionType: 'long_click',
            x: x,
            y: y,
            durationMs: 800,
            packageName: pkg,
            className: className,
            timestamp: timestamp,
          );
        }
        return null;

      case 'text_change':
        // 文本变化 → 输入动作
        if (text != null && text.isNotEmpty) {
          return TestAction(
            id: 'action_$timestamp',
            actionType: 'input',
            text: text,
            packageName: pkg,
            className: className,
            timestamp: timestamp,
          );
        }
        return null;

      case 'scroll':
        // 滚动 → 滑动动作
        if (x != null && y != null && x > 0 && y > 0) {
          return TestAction(
            id: 'action_$timestamp',
            actionType: 'swipe',
            x: x,
            y: y,
            endX: x,
            endY: (y - 500).clamp(0, 9999).toDouble(),
            durationMs: 300,
            packageName: pkg,
            className: className,
            timestamp: timestamp,
          );
        }
        return null;

      default:
        return null;
    }
  }

  double? _toDouble(dynamic v) => v is num ? v.toDouble() : null;

  /// 保存测试用例到本地文件
  Future<void> _saveTestCase(TestCase testCase) async {
    final dir = await getApplicationDocumentsDirectory();
    final testCaseDir = Directory('${dir.path}/test_cases');
    if (!await testCaseDir.exists()) {
      await testCaseDir.create(recursive: true);
    }

    final file = File('${testCaseDir.path}/${testCase.id}.json');
    await file.writeAsString(jsonEncode(testCase.toJson()));
  }

  /// 获取已保存的测试用例列表
  Future<List<TestCase>> getSavedTestCases() async {
    final dir = await getApplicationDocumentsDirectory();
    final testCaseDir = Directory('${dir.path}/test_cases');

    if (!await testCaseDir.exists()) return [];

    final files = testCaseDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();

    final cases = <TestCase>[];
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        cases.add(TestCase.fromJson(json));
      } catch (e) {
        print('加载用例失败 ${file.path}: $e');
      }
    }

    cases.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return cases;
  }

  /// 删除测试用例
  Future<void> deleteTestCase(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/test_cases/$id.json');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
