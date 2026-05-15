import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/importer/case_exporter.dart';
import '../../features/player/player_engine.dart';
import '../../models/test_case.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final _engine = PlayerEngine();
  final _cases = <TestCase>[];
  bool _isRunning = false;
  String _log = '';
  
  // 进度显示
  int _currentStep = 0;
  int _totalSteps = 0;
  String _currentAction = '';

  @override
  void initState() {
    super.initState();
    _loadTestCases();
    
    // 设置进度回调
    _engine.onProgress = (current, total, action) {
      if (mounted) {
        setState(() {
          _currentStep = current;
          _totalSteps = total;
          _currentAction = action;
          _log = '正在执行：第 $current/$total 步 ($action)\n';
        });
      }
    };
  }

  Future<void> _loadTestCases() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final testCaseDir = Directory('${dir.path}/test_cases');
      
      if (!await testCaseDir.exists()) {
        setState(() {
          _cases.clear();
        });
        return;
      }

      final files = testCaseDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final cases = <TestCase>[];
      for (final file in files) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final testCase = TestCase.fromJson(json);
          cases.add(testCase);
        } catch (e) {
          print('加载用例失败 ${file.path}: $e');
        }
      }

      // 按创建时间排序（新的在前）
      cases.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _cases.clear();
        _cases.addAll(cases);
        _log = '已加载 ${_cases.length} 个用例\n';
      });
    } catch (e) {
      setState(() {
        _log = '加载用例失败: $e\n';
      });
    }
  }

  Future<void> _runTest(TestCase tc) async {
    setState(() {
      _isRunning = true;
      _currentStep = 0;
      _totalSteps = tc.actions.length;
      _currentAction = '';
      _log = '正在执行：${tc.name}\n';
    });
    try {
      final report = await _engine.execute(tc);
      setState(() {
        _log += '完成：${report.status}\n';
        _log += '通过率：${report.passRate?.toStringAsFixed(1) ?? "-"}\n';
        _currentStep = 0;
        _totalSteps = 0;
        _currentAction = '';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('执行完成：${report.status}')),
        );
      }
    } catch (e) {
      setState(() {
        _log += '执行失败：$e\n';
        _currentStep = 0;
        _totalSteps = 0;
        _currentAction = '';
      });
    } finally {
      setState(() => _isRunning = false);
    }
  }

  Future<void> _exportCase(TestCase tc) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // 导出为 JSON
      final jsonFile = await CaseExporter.exportToJson(
        tc,
        '${exportDir.path}/${tc.name}.json',
      );

      setState(() {
        _log = '已导出：${jsonFile.path}\n';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出：${jsonFile.path}')),
        );
      }
    } catch (e) {
      setState(() {
        _log = '导出失败：$e\n';
      });
    }
  }

  Future<void> _deleteTestCase(TestCase tc) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/test_cases/${tc.id}.json');
      if (await file.exists()) {
        await file.delete();
        setState(() {
          _cases.remove(tc);
          _log = '已删除用例：${tc.name}\n';
        });
      }
    } catch (e) {
      setState(() {
        _log = '删除失败: $e\n';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickAndImportCase() async {
    // 导航到导入页面
    final result = await Navigator.pushNamed(context, '/import');
    if (result == true) {
      // 导入成功，刷新列表
      _loadTestCases();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回放执行'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRunning ? null : _loadTestCases,
            tooltip: '刷新用例列表',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('已保存用例（${_cases.length} 个）',
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
                          subtitle: Text('步骤：${tc.actions.length} | ${_formatDate(tc.createdAt)}'),
                          trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.blue),
                              onPressed: _isRunning ? null : () => _exportCase(tc),
                              tooltip: '导出',
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: _isRunning ? null : () => _runTest(tc),
                              child: const Text('执行'),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _isRunning ? null : () => _deleteTestCase(tc),
                              tooltip: '删除',
                            ),
                          ],
                        ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            // 进度显示
            if (_isRunning && _totalSteps > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('执行进度：$_currentStep/$_totalSteps',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _totalSteps > 0 ? _currentStep / _totalSteps : 0,
                  ),
                  const SizedBox(height: 4),
                  Text('当前操作：$_currentAction',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            if (_log.isNotEmpty) ...[
              const SizedBox(height: 12),
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
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _pickAndImportCase,
              icon: const Icon(Icons.add),
              label: const Text('导入用例'),
            ),
          ],
        ),
      ),
    );
  }
}
