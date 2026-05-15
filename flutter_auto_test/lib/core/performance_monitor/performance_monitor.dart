import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../models/performance_data.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  static const _channel = MethodChannel('com.tencent.autotest/performance');
  final List<PerformanceData> _data = [];
  Timer? _timer;
  String _targetPackage = '';
  bool _isMonitoring = false;
  String? _targetUid;

  List<PerformanceData> get data => List.unmodifiable(_data);
  bool get isMonitoring => _isMonitoring;

  void start(String testCaseId, String packageName) {
    _data.clear();
    _targetPackage = packageName;
    _isMonitoring = true;
    try {
      _channel.invokeMethod('getUidForPackage', {'package': packageName}).then((uid) {
        _targetUid = uid;
      });
    } catch (_) {}
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _collect(testCaseId));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isMonitoring = false;
  }

  Future<void> _collect(String testCaseId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cpu = await _getCpuUsage();
    final mem = await _getMemoryPss();
    final fps = await _getFps();
    final powerMw = await _getPowerMw();
    final batteryMa = await _getBatteryCurrentMa();
    final batteryMah = await _getBatteryDischargeMah();
    final net = await _getNetworkUsage();
    final netType = await _getNetworkType();

    _data.add(PerformanceData(
      id: 'perf_$timestamp',
      testCaseId: testCaseId,
      timestamp: timestamp,
      cpuUsage: cpu,
      memoryPssKb: mem,
      fps: fps,
      networkSentKb: net['sent'],
      networkRecvKb: net['recv'],
      networkType: netType,
      batteryMah: batteryMah,
      batteryCurrentMa: batteryMa,
      powerMw: powerMw,
    ));
  }

  Future<double?> _getCpuUsage() async {
    try {
      final result = await _channel.invokeMethod('getCpuUsage', {'package': _targetPackage});
      return result?.toDouble();
    } catch (_) {}
    return null;
  }

  Future<int?> _getMemoryPss() async {
    try {
      final result = await _channel.invokeMethod('getMemoryPss', {'package': _targetPackage});
      return result;
    } catch (_) {}
    return null;
  }

  Future<double?> _getFps() async {
    try {
      final result = await _channel.invokeMethod('getFps', {'package': _targetPackage});
      return result?.toDouble();
    } catch (_) {}
    return null;
  }

  Future<double?> _getPowerMw() async {
    try {
      final result = await _channel.invokeMethod('getPowerMw');
      return result?.toDouble();
    } catch (_) {}
    return null;
  }

  Future<double?> _getBatteryCurrentMa() async {
    try {
      final result = await _channel.invokeMethod('getBatteryCurrentMa');
      return result?.toDouble();
    } catch (_) {}
    return null;
  }

  Future<int?> _getBatteryDischargeMah() async {
    try {
      final result = await _channel.invokeMethod('getBatteryDischargeMah');
      return result;
    } catch (_) {}
    return null;
  }

  Future<Map<String, int?>> _getNetworkUsage() async {
    try {
      final result = await _channel.invokeMethod('getNetworkStats', {
        'uid': _targetUid ?? '',
      });
      if (result is Map) {
        return {
          'sent': result['sent'],
          'recv': result['recv'],
        };
      }
    } catch (_) {}
    return {'sent': null, 'recv': null};
  }

  Future<String?> _getNetworkType() async {
    try {
      return await _channel.invokeMethod('getNetworkType');
    } catch (_) {}
    return null;
  }

  String exportJson() => jsonEncode(_data.map((d) => d.toJson()).toList());

  void clear() => _data.clear();
}
