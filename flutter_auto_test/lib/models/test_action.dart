/// 测试动作模型 - 记录单个操作事件
class TestAction {
  final String id;
  final String actionType; // click / long_click / input / swipe / back / home
  final double? x;
  final double? y;
  final double? endX;
  final double? endY;
  final String? text;
  final String? packageName;
  final String? className;
  final String? elementId;
  final int timestamp;
  final int? durationMs; // 长按/滑动持续时间
  final String? screenshotPath; // 可选截图

  TestAction({
    required this.id,
    required this.actionType,
    this.x,
    this.y,
    this.endX,
    this.endY,
    this.text,
    this.packageName,
    this.className,
    this.elementId,
    required this.timestamp,
    this.durationMs,
    this.screenshotPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'actionType': actionType,
        'x': x,
        'y': y,
        'endX': endX,
        'endY': endY,
        'text': text,
        'packageName': packageName,
        'className': className,
        'elementId': elementId,
        'timestamp': timestamp,
        'durationMs': durationMs,
        'screenshotPath': screenshotPath,
      };

  factory TestAction.fromJson(Map<String, dynamic> json) => TestAction(
        id: json['id'],
        actionType: json['actionType'],
        x: json['x']?.toDouble(),
        y: json['y']?.toDouble(),
        endX: json['endX']?.toDouble(),
        endY: json['endY']?.toDouble(),
        text: json['text'],
        packageName: json['packageName'],
        className: json['className'],
        elementId: json['elementId'],
        timestamp: json['timestamp'],
        durationMs: json['durationMs'],
        screenshotPath: json['screenshotPath'],
      );
}
