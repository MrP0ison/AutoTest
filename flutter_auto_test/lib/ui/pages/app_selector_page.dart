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

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      final List<dynamic> list = jsonDecode(result ?? '[]');
      setState(() {
        _apps = list.map((e) => Map<String, String>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('选择目标 APP')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _apps.length,
              itemBuilder: (context, i) {
                final app = _apps[i];
                return ListTile(
                  leading: const Icon(Icons.android),
                  title: Text(app['appName'] ?? '未知'),
                  subtitle: Text(app['packageName'] ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(context, app['packageName']);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: 启动微信小程序（输入 appId 或原始 ID）
          _showMiniProgramDialog();
        },
        icon: const Icon(Icons.games),
        label: const Text('微信小程序'),
      ),
    );
  }

  void _showMiniProgramDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('启动微信小程序'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: '小程序原始 ID 或路径',
            hintText: '如：pages/index/index',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final path = ctrl.text.trim();
              if (path.isNotEmpty) {
                await _launchMiniProgram(path);
                Navigator.pop(context);
              }
            },
            child: const Text('启动'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchMiniProgram(String path) async {
    final url = 'weixin://dl/business/?t=$path';
    await _channel.invokeMethod('launchUrl', {'url': url});
  }
}
