import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../../core/file/file_saver.dart';
import '../../features/importer/excel_importer.dart';
import '../../features/importer/csv_importer.dart';
import '../../models/test_case.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  bool _isImporting = false;
  String _log = '';
  String _templateContent = '';

  @override
  void initState() {
    super.initState();
    _generateTemplate();
  }

  /// 生成示例 CSV 模板内容
  Future<void> _generateTemplate() async {
    _templateContent = '用例名称,目标APP包名,目标APP名称,步骤,操作类型,X坐标,Y坐标,结束X,结束Y,输入文本,元素标识,等待(ms),持续(ms),备注\n'
        '登录功能测试,com.example.app,示例APP,1,click,540,960,,,登录按钮,1000,,点击登录按钮\n'
        '登录功能测试,com.example.app,示例APP,2,input,,,,,testuser,用户名输入框,500,,输入用户名\n'
        '登录功能测试,com.example.app,示例APP,3,input,,,,,password123,密码输入框,500,,输入密码\n'
        '登录功能测试,com.example.app,示例APP,4,click,540,1200,,,,确认登录按钮,1000,,点击确认登录\n'
        '登录功能测试,com.example.app,示例APP,5,swipe,540,1600,540,400,,,500,300,上滑查看内容\n';
  }

  /// 下载模板 - 让用户选择保存位置
  Future<void> _downloadTemplate() async {
    try {
      final filePath = await FileSaver.saveTextFile(
        context: context,
        fileName: 'test_case_template.csv',
        content: _templateContent,
      );

      if (filePath != null) {
        setState(() {
          _log = '模板已保存：$filePath\n';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('模板下载成功'),
              action: SnackBarAction(
                label: '打开',
                onPressed: () => FileSaver.openFile(filePath),
              ),
            ),
          );
        }
      } else {
        setState(() {
          _log = '已取消保存\n';
        });
      }
    } catch (e) {
      setState(() {
        _log = '下载模板失败：$e\n';
      });
    }
  }

  /// 选择文件并导入
  Future<void> _pickAndImport() async {
    setState(() {
      _isImporting = true;
      _log = '正在选择文件...\n';
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv', 'json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isImporting = false;
          _log += '已取消选择\n';
        });
        return;
      }

      final file = File(result.files.first.path!);
      final extension = result.files.first.extension?.toLowerCase();

      setState(() {
        _log += '已选择文件：${result.files.first.name}\n';
        _log += '开始导入...\n';
      });

      final testCases = <TestCase>[];

      if (extension == 'xlsx') {
        testCases.addAll(await ExcelImporter.import(file));
      } else if (extension == 'csv') {
        testCases.addAll(await CsvImporter.import(file));
      } else if (extension == 'json') {
        final content = await file.readAsString();
        final json = jsonDecode(content);
        if (json is List) {
          for (final item in json) {
            testCases.add(TestCase.fromJson(item as Map<String, dynamic>));
          }
        } else {
          testCases.add(TestCase.fromJson(json as Map<String, dynamic>));
        }
      }

      setState(() {
        _log += '解析完成，共 ${testCases.length} 个用例\n';
      });

      // 保存到本地
      final dir = await getApplicationDocumentsDirectory();
      final testCaseDir = Directory('${dir.path}/test_cases');
      if (!await testCaseDir.exists()) {
        await testCaseDir.create(recursive: true);
      }

      for (final tc in testCases) {
        final file = File('${testCaseDir.path}/${tc.id}.json');
        await file.writeAsString(jsonEncode(tc.toJson()));
        setState(() {
          _log += '已保存：${tc.name}\n';
        });
      }

      setState(() {
        _log += '导入完成！\n';
        _isImporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _log += '导入失败：$e\n';
        _isImporting = false;
      });
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
            const Text(
              '支持导入以下格式：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Excel (.xlsx) - 支持多个工作表'),
            const Text('• CSV (.csv) - 逗号分隔值文件'),
            const Text('• JSON (.json) - 标准测试用例格式'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _downloadTemplate,
              icon: const Icon(Icons.download),
              label: const Text('下载示例模板(CSV)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _pickAndImport,
              icon: const Icon(Icons.file_upload),
              label: const Text('选择文件并导入'),
            ),
            const SizedBox(height: 24),
            if (_log.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _log,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
