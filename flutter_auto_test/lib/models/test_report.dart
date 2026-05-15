import 'performance_data.dart';

/// 测试报告模型
enum TestStatus { pending, running, passed, failed, stopped }

class TestReport {
  final String id;
  final String testCaseId;
  final String testCaseName;
  final DateTime startTime;
  DateTime? endTime;
  TestStatus status;
  final List<StepResult> stepResults;
  List<PerformanceData> performanceData;  // 改为可修改
  String? failureReason;
  String? screenshotDir;
  final DateTime createdAt;

  TestReport({
    required this.id,
    required this.testCaseId,
    required this.testCaseName,
    required this.startTime,
    this.endTime,
    this.status = TestStatus.pending,
    required this.stepResults,
    required this.performanceData,
    this.failureReason,
    this.screenshotDir,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;

  double? get passRate {
    if (stepResults.isEmpty) return null;
    final passed = stepResults.where((s) => s.passed).length;
    return passed / stepResults.length * 100;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'testCaseId': testCaseId,
        'testCaseName': testCaseName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'status': status.name,
        'stepResults': stepResults.map((s) => s.toJson()).toList(),
        'performanceData': performanceData.map((p) => p.toJson()).toList(),
        'failureReason': failureReason,
        'screenshotDir': screenshotDir,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TestReport.fromJson(Map<String, dynamic> json) => TestReport(
        id: json['id'],
        testCaseId: json['testCaseId'],
        testCaseName: json['testCaseName'],
        startTime: DateTime.parse(json['startTime']),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'])
            : null,
        status: TestReport._parseStatus(json['status']),
        stepResults: (json['stepResults'] as List)
            .map((s) => StepResult.fromJson(s))
            .toList(),
        performanceData: (json['performanceData'] as List? ?? [])
            .map((p) => PerformanceData.fromJson(p))
            .toList(),
        failureReason: json['failureReason'],
        screenshotDir: json['screenshotDir'],
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
      );

  static TestStatus _parseStatus(String? name) {
    if (name == null) return TestStatus.pending;
    return TestStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => TestStatus.pending,
    );
  }
}

class StepResult {
  final String actionId;
  final int stepIndex;
  final bool passed;
  final String? errorMsg;
  final String? screenshotPath;

  StepResult({
    required this.actionId,
    required this.stepIndex,
    required this.passed,
    this.errorMsg,
    this.screenshotPath,
  });

  Map<String, dynamic> toJson() => {
        'actionId': actionId,
        'stepIndex': stepIndex,
        'passed': passed,
        'errorMsg': errorMsg,
        'screenshotPath': screenshotPath,
      };

  factory StepResult.fromJson(Map<String, dynamic> json) => StepResult(
        actionId: json['actionId'],
        stepIndex: json['stepIndex'],
        passed: json['passed'],
        errorMsg: json['errorMsg'],
        screenshotPath: json['screenshotPath'],
      );
}
