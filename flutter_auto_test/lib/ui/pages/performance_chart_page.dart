import 'dart:convert';
import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/performance_data.dart';
import '../../models/test_report.dart';

class PerformanceChartPage extends StatefulWidget {
  final String reportId;
  const PerformanceChartPage({required this.reportId, super.key});

  @override
  State<PerformanceChartPage> createState() => _PerformanceChartPageState();
}

class _PerformanceChartPageState extends State<PerformanceChartPage> {
  List<PerformanceData> _cpuFpsList = [];
  List<PerformanceData> _powerBatteryList = [];
  List<PerformanceData> _networkList = [];
  bool _loading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/reports/${widget.reportId}.json');
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final json = jsonDecode(jsonStr);
        final report = TestReport.fromJson(json);
        setState(() {
          _cpuFpsList = report.performanceData;
          _powerBatteryList = report.performanceData;
          _networkList = report.performanceData;
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
        title: const Text('性能图表'),
        bottom: TabBar(
          onTap: (i) => setState(() => _tabIndex = i),
          tabs: const [
            Tab(text: 'CPU / 帧率'),
            Tab(text: '功耗 / 电池'),
            Tab(text: '网络'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildCurrentTab(),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tabIndex) {
      case 0:
        return _buildCpuFpsTab();
      case 1:
        return _buildPowerBatteryTab();
      case 2:
        return _buildNetworkTab();
      default:
        return _buildCpuFpsTab();
    }
  }

  Widget _buildCpuFpsTab() {
    final cpuSpots = <FlSpot>[];
    final fpsSpots = <FlSpot>[];
    for (var i = 0; i < _cpuFpsList.length; i++) {
      final d = _cpuFpsList[i];
      if (d.cpuUsage != null) cpuSpots.add(FlSpot(i.toDouble(), d.cpuUsage!));
      if (d.fps != null) fpsSpots.add(FlSpot(i.toDouble(), d.fps!));
    }
    if (cpuSpots.isEmpty && fpsSpots.isEmpty) {
      return const Center(child: Text('无 CPU / FPS 数据'));
    }
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}s',
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10)),
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  if (cpuSpots.isNotEmpty)
                    LineChartBarData(
                      spots: cpuSpots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  if (fpsSpots.isNotEmpty)
                    LineChartBarData(
                      spots: fpsSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
        ),
        _buildStatsRowCpuFps(),
      ],
    );
  }

  Widget _buildStatsRowCpuFps() {
    final cpuValues = _cpuFpsList.where((d) => d.cpuUsage != null).map((d) => d.cpuUsage!).toList();
    final fpsValues = _cpuFpsList.where((d) => d.fps != null).map((d) => d.fps!).toList();
    if (cpuValues.isEmpty && fpsValues.isEmpty) return const SizedBox.shrink();
    final avgCpu = cpuValues.isEmpty ? 0.0 : cpuValues.reduce((a, b) => a + b) / cpuValues.length;
    final avgFps = fpsValues.isEmpty ? 0.0 : fpsValues.reduce((a, b) => a + b) / fpsValues.length;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCard('平均 CPU', '${avgCpu.toStringAsFixed(1)}%'),
          _statCard('平均 FPS', avgFps.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _buildPowerBatteryTab() {
    final powerSpots = <FlSpot>[];
    final currentSpots = <FlSpot>[];
    for (var i = 0; i < _powerBatteryList.length; i++) {
      final d = _powerBatteryList[i];
      if (d.powerMw != null) powerSpots.add(FlSpot(i.toDouble(), d.powerMw!));
      if (d.batteryCurrentMa != null) currentSpots.add(FlSpot(i.toDouble(), d.batteryCurrentMa!));
    }
    if (powerSpots.isEmpty && currentSpots.isEmpty) {
      return const Center(child: Text('无功耗数据'));
    }
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}s',
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  if (powerSpots.isNotEmpty)
                    LineChartBarData(
                      spots: powerSpots,
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  if (currentSpots.isNotEmpty)
                    LineChartBarData(
                      spots: currentSpots,
                      isCurved: true,
                      color: Colors.redAccent,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
        ),
        _buildStatsRowPower(),
      ],
    );
  }

  Widget _buildStatsRowPower() {
    final powerValues = _powerBatteryList.where((d) => d.powerMw != null).map((d) => d.powerMw!).toList();
    final currentValues = _powerBatteryList.where((d) => d.batteryCurrentMa != null).map((d) => d.batteryCurrentMa!).toList();
    if (powerValues.isEmpty && currentValues.isEmpty) return const SizedBox.shrink();
    final avgPower = powerValues.isEmpty ? 0.0 : powerValues.reduce((a, b) => a + b) / powerValues.length;
    final avgCurrent = currentValues.isEmpty ? 0.0 : currentValues.reduce((a, b) => a + b) / currentValues.length;
    final lastMah = _powerBatteryList.where((d) => d.batteryMah != null).map((d) => d.batteryMah!).cast<int>().toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCard('平均功耗', '${avgPower.toStringAsFixed(1)} mW'),
          _statCard('平均电流', '${avgCurrent.toStringAsFixed(1)} mA'),
          _statCard('累计耗电', lastMah.isNotEmpty ? '${lastMah.last} mAh' : '-'),
        ],
      ),
    );
  }

  Widget _buildNetworkTab() {
    final sentSpots = <FlSpot>[];
    final recvSpots = <FlSpot>[];
    for (var i = 0; i < _networkList.length; i++) {
      final d = _networkList[i];
      if (d.networkSentKb != null) sentSpots.add(FlSpot(i.toDouble(), d.networkSentKb!.toDouble()));
      if (d.networkRecvKb != null) recvSpots.add(FlSpot(i.toDouble(), d.networkRecvKb!.toDouble()));
    }
    if (sentSpots.isEmpty && recvSpots.isEmpty) {
      return const Center(child: Text('无网络数据'));
    }
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}s',
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  if (sentSpots.isNotEmpty)
                    LineChartBarData(
                      spots: sentSpots,
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  if (recvSpots.isNotEmpty)
                    LineChartBarData(
                      spots: recvSpots,
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
        ),
        _buildStatsRowNetwork(),
      ],
    );
  }

  Widget _buildStatsRowNetwork() {
    final sentValues = _networkList.where((d) => d.networkSentKb != null).map((d) => d.networkSentKb!).toList();
    final recvValues = _networkList.where((d) => d.networkRecvKb != null).map((d) => d.networkRecvKb!).toList();
    final types = _networkList.where((d) => d.networkType != null).map((d) => d.networkType!).toSet();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCard('总发送', '${sentValues.isEmpty ? "-" : sentValues.reduce((a, b) => a + b).toString()} KB'),
          _statCard('总接收', '${recvValues.isEmpty ? "-" : recvValues.reduce((a, b) => a + b).toString()} KB'),
          _statCard('网络类型', types.isEmpty ? '未知' : types.join('/')),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
