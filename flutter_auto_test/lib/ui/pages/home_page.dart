import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/auth_manager/auth_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AuthState _authState = AuthState();
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final state = await AuthManager().detectAuth();
    setState(() {
      _authState = state;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AutoTest'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAuthCard(),
                const SizedBox(height: 16),
                _buildFeatureGrid(),
              ],
            ),
    );
  }

  Widget _buildAuthCard() {
    final isGranted = _authState.status == AuthStatus.granted;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isGranted ? Icons.check_circle : Icons.warning,
                  color: isGranted ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  '授权状态',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_authState.description),
            if (!isGranted) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _requestAuth,
                child: const Text('去授权'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      _FeatureItem(
        icon: Icons.fiber_manual_record,
        label: '录制用例',
        color: Colors.red,
        route: '/recorder',
      ),
      _FeatureItem(
        icon: Icons.play_arrow,
        label: '回放执行',
        color: Colors.green,
        route: '/player',
      ),
      _FeatureItem(
        icon: Icons.list_alt,
        label: '测试报告',
        color: Colors.blue,
        route: '/reports',
      ),
      _FeatureItem(
        icon: Icons.switch_account,
        label: '多账号',
        color: Colors.purple,
        route: '/accounts',
      ),
      _FeatureItem(
        icon: Icons.upload_file,
        label: '导入用例',
        color: Colors.teal,
        route: '/import',
      ),
      _FeatureItem(
        icon: Icons.apps,
        label: '目标APP',
        color: Colors.orange,
        route: '/app_selector',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('功能', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: features.map((f) {
                return InkWell(
                  onTap: () => Navigator.pushNamed(context, f.route),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(f.icon, size: 36, color: f.color),
                      const SizedBox(height: 8),
                      Text(f.label, textAlign: TextAlign.center),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestAuth() async {
    final auth = AuthManager();
    if (_authState.activeMethod == AuthMethod.none ||
        _authState.status == AuthStatus.denied) {
      // 引导用户去系统设置开启权限
      await openAppSettings();
    }
    _checkAuth();
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}
