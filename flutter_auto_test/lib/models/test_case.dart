import 'test_action.dart';

/// 测试用例模型
class TestCase {
  final String id;
  String name;
  String description;
  final String targetAppPackage; // 目标APP包名
  final String targetAppName;
  final List<TestAction> actions;
  final DateTime createdAt;
  DateTime? updatedAt;
  bool isTemplate; // 是否为导入的模板用例
  Map<String, dynamic>? expectedPerformance; // 预期性能指标

  TestCase({
    required this.id,
    required this.name,
    this.description = '',
    required this.targetAppPackage,
    this.targetAppName = '',
    required this.actions,
    required this.createdAt,
    this.updatedAt,
    this.isTemplate = false,
    this.expectedPerformance,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'targetAppPackage': targetAppPackage,
        'targetAppName': targetAppName,
        'actions': actions.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'isTemplate': isTemplate,
        'expectedPerformance': expectedPerformance,
      };

  factory TestCase.fromJson(Map<String, dynamic> json) => TestCase(
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        targetAppPackage: json['targetAppPackage'],
        targetAppName: json['targetAppName'] ?? '',
        actions: (json['actions'] as List<dynamic>)
            .map((a) => TestAction.fromJson(a as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        isTemplate: json['isTemplate'] ?? false,
        expectedPerformance: json['expectedPerformance'],
      );
}
