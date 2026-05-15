import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/permission/permission_util.dart';
import '../../features/recorder/recorder_engine.dart';
import '../../models/test_case.dart';
import '../widgets/floating_control_panel.dart';

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  final _engine = RecorderEngine();
  bool _isRecording = false;
  String _log = '';
  List<TestCase> _savedCases = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadSavedCases();
  }

  /// 检查并申请权限
  Future<void> _checkPermissions() async {
    final enabled = await PermissionUtil.isAccessibilityEnabled();
    if (!enabled && mounted) {
      await PermissionUtil.requestAllPermissions(context);
    }
  }

  /// 加载已保存的用例
  Future<void> _loadSavedCases() async {
    try {
      final cases = await _engine.getSavedTestCases();
      setState(() {
        _savedCases = cases;
      });
    } catch (e) {
      print('加载用例失败: $e');
    }
  }

  /// 切换录制状态
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // 停止录制
      try {
        final tc = await _engine.stopRecording();
        setState(() {
          _isRecording = false;
          _log += '已保存：${tc.name}\n';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存成功：${tc.name}')),
        );
        _loadSavedCases(); // 刷新列表
      } catch (e) {
        setState(() {
          _isRecording = false;
          _log += '保存失败：$e\n';
        });
      }
    } else {
      // 检查权限
      final enabled = await PermissionUtil.isAccessibilityEnabled();
      if (!enabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请先开启无障碍服务')),
          );
          await PermissionUtil.requestAllPermissions(context);
        }
        return;
      }

      // 开始录制
      try {
        final id = 'tc_${DateTime.now().millisecondsSinceEpoch}';
        await _engine.startRecording(id);
        setState(() {
          _isRecording = true;
          _log += '开始录制：$id\n';
        });
      } catch (e) {
        setState(() {
          _log += '启动失败：$e\n';
        });
      }
    }
  }

  /// 删除用例
  Future<void> _deleteCase(TestCase tc) async {
    try {
      await _engine.deleteTestCase(tc.id);
      setState(() {
        _savedCases.remove(tc);
        _log += '已删除：${tc.name}\n';
      });
    } catch (e) {
      setState(() {
        _log += '删除失败：$e\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录制用例'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedCases,
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => PermissionUtil.openAccessibilitySettings(),
            tooltip: '开启无障碍',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 录制控制区域
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isRecording
                          ? Icons.fiber_manual_record
                          : Icons.radio_button_unchecked,
                      size: 64,
                      color: _isRecording ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRecording ? '正在录制...\n请在目标APP中操作' : '点击开始录制',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _toggleRecording,
                      icon: Icon(
                        _isRecording ? Icons.stop : Icons.fiber_manual_record,
                      ),
                      label: Text(_isRecording ? '停止录制' : '开始录制'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isRecording ? Colors.red : null,
                        foregroundColor:
                            _isRecording ? Colors.white : null,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 悬浮窗控制按钮
                    TextButton.icon(
                      onPressed: () async {
                        await FloatingControlPanel().toggle();
                        setState(() {});
                      },
                      icon: Icon(
                        FloatingControlPanel().isVisible ? Icons.visibility_off : Icons.visibility,
                      ),
                      label: Text(FloatingControlPanel().isVisible ? '隐藏悬浮窗' : '显示悬浮窗'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 已保存的用例列表
            Text(
              '已保存用例（${_savedCases.length} 个）',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _savedCases.isEmpty
                  ? const Center(child: Text('暂无用例，请先录制'))
                  : ListView.builder(
                      itemCount: _savedCases.length,
                      itemBuilder: (context, i) {
                        final tc = _savedCases[i];
                        return ListTile(
                          leading: const Icon(Icons.description),
                          title: Text(tc.name),
                          subtitle: Text(
                            '步骤：${tc.actions.length} | ${_formatDate(tc.createdAt)}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteCase(tc),
                            tooltip: '删除',
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),

            // 日志区域
            if (_log.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => PermissionUtil.openAccessibilitySettings(),
        tooltip: '开启无障碍服务',
        child: const Icon(Icons.settings),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
