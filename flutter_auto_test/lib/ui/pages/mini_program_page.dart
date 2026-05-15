/// 小程序选择页面 - 用于选择并启动微信小程序
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MiniProgramPage extends StatefulWidget {
  const MiniProgramPage({super.key});

  @override
  State<MiniProgramPage> createState() => _MiniProgramPageState();
}

class _MiniProgramPageState extends State<MiniProgramPage> {
  final _channel = const MethodChannel('com.tencent.autotest/accessibility');
  final _controller = TextEditingController();
  final _miniPrograms = [
    {'name': '示例小程序', 'id': 'gh_xxxxxxxxxxxx', 'path': 'pages/index/index'},
    {'name': '测试小程序A', 'id': 'gh_test123456', 'path': 'pages/home/home'},
    {'name': '测试小程序B', 'id': 'gh_demo789012', 'path': 'pages/main/main'},
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择小程序'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: '使用说明',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索/输入区域
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '输入小程序信息',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: '小程序路径或ID',
                        hintText: '如：pages/index/index 或 gh_xxxxxxxxxxxx',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _launchMiniProgram,
                      icon: const Icon(Icons.launch),
                      label: const Text('启动小程序'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '常用小程序',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          // 常用小程序列表
          Expanded(
            child: ListView.builder(
              itemCount: _miniPrograms.length,
              itemBuilder: (context, index) {
                final mp = _miniPrograms[index];
                return ListTile(
                  leading: const Icon(Icons.games, color: Colors.green),
                  title: Text(mp['name']!),
                  subtitle: Text('ID: ${mp['id']}\n路径: ${mp['path']}'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.launch, color: Colors.blue),
                    onPressed: () => _launchSpecificMiniProgram(mp),
                    tooltip: '启动',
                  ),
                  onTap: () => _launchSpecificMiniProgram(mp),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 启动输入的小程序
  Future<void> _launchMiniProgram() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入小程序路径或ID')),
      );
      return;
    }

    try {
      // 尝试通过微信 URL Scheme 启动小程序
      final url = 'weixin://dl/business/?t=$input';
      await _channel.invokeMethod('launchUrl', {'url': url});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在启动小程序...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('启动失败: $e')),
      );
    }
  }

  /// 启动指定的小程序
  Future<void> _launchSpecificMiniProgram(Map<String, String> mp) async {
    try {
      final url = 'weixin://dl/business/?t=${mp['path']}';
      await _channel.invokeMethod('launchUrl', {'url': url});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('正在启动 ${mp['name']}...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('启动失败: $e')),
      );
    }
  }

  /// 显示使用说明
  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('使用说明'),
        content: const Text(
          '1. 在输入框中输入小程序路径或原始ID\n'
          '2. 点击"启动小程序"按钮\n'
          '3. 或从常用小程序列表中选择\n\n'
          '注意：需要确保微信已安装并登录',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
