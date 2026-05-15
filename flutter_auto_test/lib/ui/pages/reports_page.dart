import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'performance_chart_page.dart';

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
            .where((f) => f.path.endsWith('.txt') || f.path.endsWith('.json'))
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
      appBar: AppBar(title: const Text('测试报告')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? const Center(child: Text('暂无报告，请先执行测试'))
              : ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, i) {
                    final file = _files[i];
                    final name = file.path.split('/').last;
                    final isJson = file.path.endsWith('.json');
                    return ListTile(
                      leading: Icon(isJson ? Icons.show_chart : Icons.description),
                      title: Text(name),
                      subtitle: isJson ? const Text('点击查看性能图表') : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openReport(context, file.path, isJson),
                    );
                  },
                ),
    );
  }

  void _openReport(BuildContext context, String path, bool isJson) {
    if (isJson) {
      // 提取 reportId（文件名去掉 .json 后缀）
      final fileName = path.split('/').last;
      final reportId = fileName.replaceAll('.json', '');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PerformanceChartPage(reportId: reportId),
        ),
      );
    } else {
      _viewRawReport(context, path);
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
}
