import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'performance_chart_page.dart';
import '../../core/report_generator/html_report_builder.dart';
import '../../core/report_generator/excel_report_builder.dart';
import '../../core/file/file_saver.dart';
import '../../models/test_report.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<FileSystemEntity> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${dir.path}/reports');
      if (await reportsDir.exists()) {
        final files = reportsDir
            .listSync()
            .where((f) =>
                f.path.endsWith('.txt') ||
                f.path.endsWith('.json') ||
                f.path.endsWith('.html') ||
                f.path.endsWith('.xlsx') ||
                f.path.endsWith('.csv'))
            .toList();
        setState(() {
          _files = files;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('测试报告'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadReports(),
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            onPressed: _confirmDeleteAll,
            tooltip: '清空所有报告',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(child: Text('暂无报告，请先执行测试'))
              : ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, i) {
                    final file = _files[i];
                    final name = file.path.split('/').last;
                    final ext = name.split('.').last.toLowerCase();
                    return ListTile(
                      leading: Icon(_getIcon(ext)),
                      title: Text(name),
                      subtitle: Text(_getSubtitle(ext)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download,
                                color: Colors.blue),
                            onPressed: () => _exportReport(context, file.path),
                            tooltip: '导出',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteReport(context, file.path),
                            tooltip: '删除',
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => _openReport(context, file.path, ext),
                    );
                  },
                ),
    );
  }

  IconData _getIcon(String ext) {
    switch (ext) {
      case 'json':
        return Icons.show_chart;
      case 'txt':
        return Icons.description;
      case 'html':
        return Icons.html;
      case 'xlsx':
        return Icons.table_chart;
      case 'csv':
        return Icons.table_rows;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getSubtitle(String ext) {
    switch (ext) {
      case 'json':
        return '性能数据';
      case 'txt':
        return '功能报告';
      case 'html':
        return 'HTML报告';
      case 'xlsx':
        return 'Excel报告';
      case 'csv':
        return 'CSV数据';
      default:
        return '';
    }
  }

  void _openReport(BuildContext context, String path, String ext) {
    if (ext == 'json') {
      final fileName = path.split('/').last;
      final reportId = fileName.replaceAll('.json', '');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PerformanceChartPage(reportId: reportId),
        ),
      );
    } else if (ext == 'txt' || ext == 'html') {
      _viewRawReport(context, path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件已保存：$path')),
      );
    }
  }

  void _viewRawReport(BuildContext context, String path) async {
    final content = await File(path).readAsString();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(path.split('/').last),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport(BuildContext context, String path) async {
    try {
      final ext = path.split('.').last.toLowerCase();

      if (ext == 'json') {
        // 生成 HTML 和 Excel 报告
        final content = await File(path).readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final report = TestReport.fromJson(json);

        // 生成 HTML 报告
        final htmlFile = await HtmlReportBuilder.build(report);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已生成HTML报告：${htmlFile.path}'),
              action: SnackBarAction(
                label: '打开',
                onPressed: () => FileSaver.openFile(htmlFile.path),
              ),
            ),
          );
        }

        // 生成 Excel 报告
        final excelFile = await ExcelReportBuilder.build(report);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已生成Excel报告：${excelFile.path}'),
              action: SnackBarAction(
                label: '打开',
                onPressed: () => FileSaver.openFile(excelFile.path),
              ),
            ),
          );
        }

        _loadReports(); // 刷新列表
      } else {
        // 直接导出已有文件（让用户选择保存位置）
        final fileName = path.split('/').last;
        final bytes = await File(path).readAsBytes();
        final savedPath = await FileSaver.saveFile(
          context: context,
          fileName: fileName,
          bytes: bytes,
        );

        if (savedPath != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已导出：$savedPath'),
              action: SnackBarAction(
                label: '打开',
                onPressed: () => FileSaver.openFile(savedPath),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败：$e')),
        );
      }
    }
  }

  Future<void> _deleteReport(BuildContext context, String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${path.split('/').last}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final file = File(path);
        await file.delete();
        setState(() {
          _files.removeWhere((f) => f.path == path);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已删除')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败：$e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteAll() async {
    if (_files.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要删除所有报告吗？此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (final file in _files) {
          await File(file.path).delete();
        }
        setState(() {
          _files.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已清空所有报告')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('清空失败：$e')),
          );
        }
      }
    }
  }
}
