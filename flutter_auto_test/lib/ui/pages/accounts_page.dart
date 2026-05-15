import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});
  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  List<Map<String, String>> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/accounts.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> list = jsonDecode(content);
        setState(() {
          _accounts = list.map((e) => Map<String, String>.from(e)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAccounts() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/accounts.json');
    await file.writeAsString(jsonEncode(_accounts));
  }

  void _addAccount() {
    final nameCtrl = TextEditingController();
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String type = '微信';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('添加账号'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: type,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: '微信', child: Text('微信')),
                  DropdownMenuItem(value: 'QQ', child: Text('QQ')),
                  DropdownMenuItem(value: '游客', child: Text('游客')),
                  DropdownMenuItem(value: '其他', child: Text('其他')),
                ],
                onChanged: (v) => setDialogState(() => type = v!),
              ),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '账号名称')),
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: '用户名')),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: '密码'), obscureText: true),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () {
                _accounts.add({
                  'name': nameCtrl.text,
                  'type': type,
                  'username': userCtrl.text,
                  'password': passCtrl.text,
                });
                _saveAccounts();
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAccount(int index) {
    setState(() => _accounts.removeAt(index));
    _saveAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('多账号管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? const Center(child: Text('暂无账号，点击 + 添加'))
              : ListView.builder(
                  itemCount: _accounts.length,
                  itemBuilder: (context, i) {
                    final a = _accounts[i];
                    return ListTile(
                      leading: const Icon(Icons.account_circle),
                      title: Text(a['name'] ?? ''),
                      subtitle: Text('${a['type'] ?? ""}  ${a['username'] ?? ""}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteAccount(i),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccount,
        child: const Icon(Icons.add),
      ),
    );
  }
}
