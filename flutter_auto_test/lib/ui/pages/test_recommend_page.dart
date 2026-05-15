import 'dart:convert';
import 'package:flutter/material.dart';
import '../../features/analyzer/app_analyzer.dart';
import '../../features/analyzer/test_recommender.dart';
import '../../models/test_case.dart';

class TestRecommendPage extends StatefulWidget {
  final String targetPackage;
  final String targetAppName;

  const TestRecommendPage({
    super.key,
    required this.targetPackage,
    required this.targetAppName,
  });

  @override
  State<TestRecommendPage> createState() => _TestRecommendPageState();
}

class _TestRecommendPageState extends State<TestRecommendPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _uiTree;
  String _appType = '';
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _analyzeAndRecommend();
  }

  Future<void> _analyzeAndRecommend() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取UI树
      final tree = await AppAnalyzer.getUiTree(maxDepth: 10);

      if (tree == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _uiTree = tree;
      });

      // 分析APP类型
      final appType = AppAnalyzer.analyzeAppType(tree);
      setState(() {
        _appType = appType;
      });

      // 推荐测试
      final recommendations = TestRecommender.recommendTests(tree, appType);
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('测试推荐'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _analyzeAndRecommend,
            tooltip: '重新分析',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '目标APP：${widget.targetAppName}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('APP类型：$_appType'),
                      const SizedBox(height: 4),
                      Text('推荐测试：${_recommendations.length} 个'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _recommendations.isEmpty
                      ? const Center(child: Text('暂无推荐，请先分析APP'))
                      : ListView.builder(
                          itemCount: _recommendations.length,
                          itemBuilder: (context, i) {
                            final rec = _recommendations[i];
                            return ListTile(
                              leading: const Icon(Icons.assignment),
                              title: Text(rec['name']),
                              subtitle: Text(rec['description'] ?? ''),
                              trailing: ElevatedButton(
                                onPressed: () => _createTestCase(rec),
                                child: const Text('生成用例'),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _createTestCase(Map<String, dynamic> recommendation) async {
    try {
      final testCase = TestRecommender.toTestCase(
        recommendation,
        widget.targetPackage,
        widget.targetAppName,
      );

      // 保存到本地
      final json = jsonEncode(testCase.toJson());
      // 这里需要实现保存到本地文件的逻辑
      // 暂时用SnackBar显示成功信息

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已生成用例：${testCase.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败：$e')),
        );
      }
    }
  }
}
