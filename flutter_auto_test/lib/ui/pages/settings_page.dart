import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _cpuController = TextEditingController();
  final _memController = TextEditingController();
  final _fpsController = TextEditingController();
  final _powerController = TextEditingController();
  final _batteryController = TextEditingController();
  final _networkSentController = TextEditingController();
  final _networkRecvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cpuController.text = prefs.getString('expected_cpu') ?? '80';
      _memController.text = prefs.getString('expected_memory_mb') ?? '512';
      _fpsController.text = prefs.getString('expected_min_fps') ?? '30';
      _powerController.text = prefs.getString('expected_max_power_mw') ?? '2000';
      _batteryController.text = prefs.getString('expected_max_current_ma') ?? '500';
      _networkSentController.text = prefs.getString('expected_max_sent_kb') ?? '10240';
      _networkRecvController.text = prefs.getString('expected_max_recv_kb') ?? '10240';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expected_cpu', _cpuController.text);
    await prefs.setString('expected_memory_mb', _memController.text);
    await prefs.setString('expected_min_fps', _fpsController.text);
    await prefs.setString('expected_max_power_mw', _powerController.text);
    await prefs.setString('expected_max_current_ma', _batteryController.text);
    await prefs.setString('expected_max_sent_kb', _networkSentController.text);
    await prefs.setString('expected_max_recv_kb', _networkRecvController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('预期性能指标（超标时报告标红）',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _cpuController,
            decoration: const InputDecoration(
              labelText: '最大 CPU 使用率（%）',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memController,
            decoration: const InputDecoration(
              labelText: '最大内存占用（MB）',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fpsController,
            decoration: const InputDecoration(
              labelText: '最低 FPS',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _powerController,
            decoration: const InputDecoration(
              labelText: '最大功耗（mW）',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _batteryController,
            decoration: const InputDecoration(
              labelText: '最大电流（mA）',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _networkSentController,
            decoration: const InputDecoration(
              labelText: '最大发送流量（KB）',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _networkRecvController,
            decoration: const InputDecoration(
              labelText: '最大接收流量（KB）',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('保存设置'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cpuController.dispose();
    _memController.dispose();
    _fpsController.dispose();
    _powerController.dispose();
    _batteryController.dispose();
    _networkSentController.dispose();
    _networkRecvController.dispose();
    super.dispose();
  }
}
