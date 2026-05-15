import 'package:flutter/material.dart';
import '../../features/player/player_engine.dart';
import '../../models/test_case.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final _engine = PlayerEngine();
  final _cases = <TestCase>[]; // TODO: 从本地加载已保存的用例
  bool _isRunning = false;
  String _log = '';

  Future<void> _runTest(TestCase tc) async {
    setState(() {
      _isRunning = true;
      _log = '正在执行：${tc.name}\n';
    });
    try {
      final report = await _engine.execute(tc);
      setState(() {
        _log += '完成：\${report.status}\n';
        _log += '通过率：\${report.passRate?.toStringAsFixed(1) ?? "-"}\%\n';
      });
    } catch (e) {
      setState(() => _log += '执行失败：\$e\n');
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('回放执行')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('已保存用例（\${_cases.length} 个）',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: _cases.isEmpty
                  ? const Center(child: Text('暂无用例，请先录制'))
                  : ListView.builder(
                      itemCount: _cases.length,
                      itemBuilder: (context, i) {
                        final tc = _cases[i];
                        return ListTile(
                          leading: const Icon(Icons.description),
                          title: Text(tc.name),
                          subtitle: Text('步骤：\${tc.actions.length}'),
                          trailing: ElevatedButton(
                            onPressed: _isRunning ? null : () => _runTest(tc),
                            child: const Text('执行'),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            if (_log.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(_log, style: const TextStyle(fontFamily: 'monospace')),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : null, // TODO: 跳转到导入/选择用例
              icon: const Icon(Icons.add),
              label: const Text('选择用例'),
            ),
          ],
        ),
      ),
    );
  }
}
