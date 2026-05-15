import 'package:flutter/material.dart';
import '../../features/recorder/recorder_engine.dart';

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  final _engine = RecorderEngine();
  bool _isRecording = false;
  String _log = '';

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
      } catch (e) {
        setState(() => _log += '保存失败：$e\n');
      }
    } else {
      // 开始录制
      final id = 'tc_${DateTime.now().millisecondsSinceEpoch}';
      try {
        await _engine.startRecording(id);
        setState(() {
          _isRecording = true;
          _log += '开始录制：$id\n';
        });
      } catch (e) {
        setState(() => _log += '启动失败：$e\n');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('录制用例')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              _isRecording ? Icons.fiber_manual_record : Icons.radio_button_unchecked,
              size: 80,
              color: _isRecording ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _isRecording ? '正在录制...\n请在目标APP中操作' : '点击开始录制',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _toggleRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
              label: Text(_isRecording ? '停止录制' : '开始录制'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : null,
                foregroundColor: _isRecording ? Colors.white : null,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            Text('操作日志', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(_log, style: const TextStyle(fontFamily: 'monospace')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
