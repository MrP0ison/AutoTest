/// App 分析器 - 分析当前前台APP的UI结构
import 'dart:convert';
import 'package:flutter/services.dart';

class AppAnalyzer {
  static final _channel = const MethodChannel('com.tencent.autotest/accessibility');

  /// 获取当前UI树
  static Future<Map<String, dynamic>?> getUiTree({int maxDepth = 10}) async {
    try {
      final jsonStr = await _channel.invokeMethod<String>('getUiTree', {
        'maxDepth': maxDepth,
      });
      if (jsonStr == null) return null;
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      print('获取UI树失败: $e');
      return null;
    }
  }

  /// 解析UI树，提取可交互元素
  static List<Map<String, dynamic>> extractInteractiveElements(
    Map<String, dynamic> tree,
  ) {
    final elements = <Map<String, dynamic>>[];

    void traverse(Map<String, dynamic> node) {
      // 检查是否可点击或可聚焦
      final isClickable = node['isClickable'] == true;
      final isFocusable = node['isFocusable'] == true;
      final isEditable = node['isEditable'] == true;
      final isScrollable = node['isScrollable'] == true;

      if (isClickable || isFocusable || isEditable) {
        final element = <String, dynamic>{
          'className': node['className'],
          'text': node['text'],
          'contentDescription': node['contentDescription'],
          'isClickable': isClickable,
          'isEditable': isEditable,
          'isFocusable': isFocusable,
          'isScrollable': isScrollable,
        };

        // 添加坐标信息
        if (node['bounds'] != null) {
          element['bounds'] = node['bounds'];
          element['centerX'] = node['bounds']['centerX'];
          element['centerY'] = node['bounds']['centerY'];
        }

        elements.add(element);
      }

      // 递归遍历子节点
      if (node['children'] != null) {
        final children = node['children'] as List<dynamic>;
        for (final child in children) {
          traverse(child as Map<String, dynamic>);
        }
      }
    }

    traverse(tree);
    return elements;
  }

  /// 分析APP类型（登录页、列表页、表单页等）
  static String analyzeAppType(Map<String, dynamic> tree) {
    final elements = extractInteractiveElements(tree);
    
    var hasEditText = false;
    var hasButton = false;
    var hasListView = false;
    var hasLoginText = false;

    for (final element in elements) {
      final className = element['className']?.toString() ?? '';
      final text = element['text']?.toString().toLowerCase() ?? '';

      if (className.contains('EditText') || element['isEditable'] == true) {
        hasEditText = true;
      }
      if (className.contains('Button') || element['isClickable'] == true) {
        hasButton = true;
      }
      if (className.contains('ListView') || className.contains('RecyclerView')) {
        hasListView = true;
      }
      if (text.contains('登录') || text.contains('login') || text.contains('注册') || text.contains('register')) {
        hasLoginText = true;
      }
    }

    if (hasEditText && hasButton && hasLoginText) {
      return '登录页';
    } else if (hasListView) {
      return '列表页';
    } else if (hasEditText) {
      return '表单页';
    } else if (hasButton) {
      return '功能页';
    } else {
      return '未知类型';
    }
  }
}
