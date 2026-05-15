/// APP 选择器页面 - 用于选择已安装的APP进行自动化测试
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppSelectorPage extends StatefulWidget {
  const AppSelectorPage({super.key});

  @override
  State<AppSelectorPage> createState() => _AppSelectorPageState();
}

class _AppSelectorPageState extends State<AppSelectorPage> {
  final _channel = const MethodChannel('com.tencent.autotest/accessibility');
  List<Map<String, String>> _apps = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      final List<dynamic> list = result is String ? jsonDecode(result) : (result ?? []);
      setState(() {
        _apps = list.map((e) => Map<String, String>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载应用列表失败: $e')),
        );
      }
    }
  }

  List<Map<String, String>> get _filteredApps {
    if (_searchQuery.isEmpty) return _apps;
    return _apps.where((app) {
      final name = app['appName']?.toLowerCase() ?? '';
      final pkg = app['packageName']?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || pkg.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择目标 APP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApps,
            tooltip: '刷新',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: '搜索应用',
                hintText: '输入应用名称或包名',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // 应用列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredApps.isEmpty
                    ? const Center(child: Text('未找到匹配的应用'))
                    : ListView.builder(
                        itemCount: _filteredApps.length,
                        itemBuilder: (context, i) {
                          final app = _filteredApps[i];
                          return ListTile(
                            leading: const Icon(Icons.android, color: Colors.green),
                            title: Text(app['appName'] ?? '未知'),
                            subtitle: Text(app['packageName'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.analytics, color: Colors.blue),
                                  onPressed: () => _analyzeApp(app),
                                  tooltip: '分析APP',
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () => _selectApp(app),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// 选择APP后的引导流程
  Future<void> _selectApp(Map<String, String> app) async {
    final packageName = app['packageName'] ?? '';
    final appName = app['appName'] ?? '';

    if (packageName.isEmpty) return;

    // 显示引导对话框
    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('已选择: $appName'),
        content: const Text(
          '请选择下一步操作：\n\n'
          '1. 分析APP结构 - 自动分析并推荐测试用例\n'
          '2. 选择已有用例 - 从已保存的用例中选择\n'
          '3. 录制新用例 - 开始录制新的测试用例',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'analyze'),
            child: const Text('分析APP结构'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'select'),
            child: const Text('选择已有用例'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'record'),
            child: const Text('录制新用例'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (action == null) return;

    switch (action) {
      case 'analyze':
        // 跳转到APP结构分析页面
        await Navigator.pushNamed(
          context,
          '/test_recommend',
          arguments: {
            'targetPackage': packageName,
            'targetAppName': appName,
          },
        );
        break;
      case 'select':
        // 跳转到用例选择页面
        await _selectTestCase(packageName, appName);
        break;
      case 'record':
        // 跳转到录制页面
        await Navigator.pushNamed(context, '/recorder');
        break;
    }
  }

  /// 分析APP
  Future<void> _analyzeApp(Map<String, String> app) async {
    try {
      await Navigator.pushNamed(
        context,
        '/app_structure',
        arguments: {
          'packageName': app['packageName'],
          'appName': app['appName'],
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分析失败: $e')),
        );
      }
    }
  }

  /// 选择测试用例
  Future<void> _selectTestCase(String packageName, String appName) async {
    // 跳转到回放页面，并传递包名参数用于过滤用例
    final result = await Navigator.pushNamed(
      context,
      '/player',
      arguments: {
        'targetPackage': packageName,
        'targetAppName': appName,
      },
    );
    
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('测试完成：$result')),
      );
    }
  }
}
