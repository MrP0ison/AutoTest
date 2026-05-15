/// 性能数据采集模型
class PerformanceData {
  final String id;
  final String testCaseId;
  final int timestamp; // 采集时间戳（毫秒）
  final double? cpuUsage; // CPU 使用率（%）
  final int? memoryPssKb; // 内存 PSS（KB）
  final double? fps; // 帧率
  final int? networkSentKb; // 发送流量（KB）
  final int? networkRecvKb; // 接收流量（KB）
  final String? networkType; // 网络类型（WiFi / Mobile / None）
  final int? batteryMah; // 电池累计消耗（mAh）
  final double? batteryCurrentMa; // 电池实时电流（mA，正值=放电）
  final double? powerMw; // 实时功耗（mW = V × I）

  PerformanceData({
    required this.id,
    required this.testCaseId,
    required this.timestamp,
    this.cpuUsage,
    this.memoryPssKb,
    this.fps,
    this.networkSentKb,
    this.networkRecvKb,
    this.networkType,
    this.batteryMah,
    this.batteryCurrentMa,
    this.powerMw,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'testCaseId': testCaseId,
        'timestamp': timestamp,
        'cpuUsage': cpuUsage,
        'memoryPssKb': memoryPssKb,
        'fps': fps,
        'networkSentKb': networkSentKb,
        'networkRecvKb': networkRecvKb,
        'networkType': networkType,
        'batteryMah': batteryMah,
        'batteryCurrentMa': batteryCurrentMa,
        'powerMw': powerMw,
      };

  factory PerformanceData.fromJson(Map<String, dynamic> json) => PerformanceData(
        id: json['id'],
        testCaseId: json['testCaseId'],
        timestamp: json['timestamp'],
        cpuUsage: json['cpuUsage']?.toDouble(),
        memoryPssKb: json['memoryPssKb'],
        fps: json['fps']?.toDouble(),
        networkSentKb: json['networkSentKb'],
        networkRecvKb: json['networkRecvKb'],
        networkType: json['networkType'],
        batteryMah: json['batteryMah'],
        batteryCurrentMa: json['batteryCurrentMa']?.toDouble(),
        powerMw: json['powerMw']?.toDouble(),
      );
}
