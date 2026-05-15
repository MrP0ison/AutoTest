import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/test_case.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  String _log = '';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path!;
    try {
      final content = await File(path).readAsString();
      final json = jsonDecode(content);
      final tc = TestCase.fromJson(json);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/test_cases/${tc.id}.json');
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(tc.toJson()));
      setState(() {
        _log = '导入成功：${tc.name}\n$_log';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入成功')),
      );
    } catch (e) {
      setState(() => _log = '导入失败：$e\n$_log');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入用例')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('支持 JSON 格式用例文件', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('选择文件'),
            ),
            const SizedBox(height: 16),
            if (_log.isNotEmpty) ...[
              const Text('操作日志', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(_log, style: const TextStyle(fontFamily: 'monospace')),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
