import 'dart:convert';
import 'package:flutter/material.dart';
import '../../features/analyzer/app_analyzer.dart';

class AppStructurePage extends StatefulWidget {
  const AppStructurePage({super.key});

  @override
  State<AppStructurePage> createState() => _AppStructurePageState();
}

class _AppStructurePageState extends State<AppStructurePage> {
  bool _isAnalyzing = false;
  Map<String, dynamic>? _uiTree;
  List<Map<String, dynamic>> _elements = [];
  String _appType = '';
  String _log = '';

  Future<void> _analyzeCurrentApp() async {
    setState(() {
      _isAnalyzing = true;
      _log = '正在分析当前APP...\n';
    });

    try {
      final tree = await AppAnalyzer.getUiTree(maxDepth: 10);

      if (tree == null) {
        setState(() {
          _log += '分析失败：无法获取UI树\n';
          _isAnalyzing = false;
        });
        return;
      }

      setState(() {
        _uiTree = tree;
        _log += 'UI树获取成功\n';
      });

      // 提取可交互元素
      final elements = AppAnalyzer.extractInteractiveElements(tree);
      setState(() {
        _elements = elements;
        _log += '提取到 ${elements.length} 个可交互元素\n';
      });

      // 分析APP类型
      final appType = AppAnalyzer.analyzeAppType(tree);
      setState(() {
        _appType = appType;
        _log += 'APP类型：$appType\n';
      });

      setState(() {
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _log = '分析失败：$e\n';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APP结构分析'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _isAnalyzing ? null : _analyzeCurrentApp,
            tooltip: '分析当前APP',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_appType.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('APP类型：$_appType',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('可交互元素：${_elements.length} 个'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              '可交互元素列表：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _elements.isEmpty
                  ? const Center(child: Text('请先点击右上角按钮分析当前APP'))
                  : ListView.builder(
                      itemCount: _elements.length,
                      itemBuilder: (context, i) {
                        final e = _elements[i];
                        return ListTile(
                          leading: Icon(
                            e['isClickable'] == true
                                ? Icons.touch_app
                                : e['isEditable'] == true
                                    ? Icons.edit
                                    : Icons.info,
                          ),
                          title: Text(e['text'] ?? e['className'] ?? '未知'),
                          subtitle: Text(
                            '${e['isClickable'] == true ? "可点击 " : ""}'
                            '${e['isEditable'] == true ? "可编辑 " : ""}'
                            '${e['text'] != null ? "文本 " : ""}',
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
                  child: Text(
                    _log,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
