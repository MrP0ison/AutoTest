/// 测试推荐器 - 根据UI树推荐测试场景
import '../../models/test_case.dart';
import '../../models/test_action.dart';
import 'app_analyzer.dart';

class TestRecommender {
  /// 根据UI树推荐测试场景
  static List<Map<String, dynamic>> recommendTests(
    Map<String, dynamic> uiTree,
    String appType,
  ) {
    final elements = AppAnalyzer.extractInteractiveElements(uiTree);
    final recommendations = <Map<String, dynamic>>[];

    // 根据APP类型推荐
    switch (appType) {
      case '登录页':
        _addLoginTest(elements, recommendations);
        break;
      case '列表页':
        _addListTest(elements, recommendations);
        break;
      case '表单页':
        _addFormTest(elements, recommendations);
        break;
      case '功能页':
        _addFunctionTest(elements, recommendations);
        break;
      default:
        _addBasicTest(elements, recommendations);
    }

    return recommendations;
  }

  /// 推荐登录测试
  static void _addLoginTest(
    List<Map<String, dynamic>> elements,
    List<Map<String, dynamic>> recommendations,
  ) {
    // 查找用户名/密码输入框
    final usernameFields = elements.where((e) =>
        e['isEditable'] == true ||
        (e['text']?.toString().contains('用户') ?? false) ||
        (e['text']?.toString().contains('账号') ?? false));
    
    final passwordFields = elements.where((e) =>
        (e['text']?.toString().contains('密码') ?? false) ||
        (e['className']?.toString().contains('Password') ?? false));

    // 查找登录按钮
    final loginButtons = elements.where((e) =>
        (e['text']?.toString().contains('登录') ?? false) ||
        (e['text']?.toString().contains('Login') ?? false));

    if (usernameFields.isNotEmpty && passwordFields.isNotEmpty) {
      recommendations.add({
        'name': '登录功能测试',
        'description': '测试用户登录功能',
        'actions': [
          ...usernameFields.map((e) => {
            'actionType': 'input',
            'x': e['centerX'],
            'y': e['centerY'],
            'text': 'testuser',
          }),
          ...passwordFields.map((e) => {
            'actionType': 'input',
            'x': e['centerX'],
            'y': e['centerY'],
            'text': 'password123',
          }),
          ...loginButtons.map((e) => {
            'actionType': 'click',
            'x': e['centerX'],
            'y': e['centerY'],
          }),
        ],
      });
    }
  }

  /// 推荐列表测试
  static void _addListTest(
    List<Map<String, dynamic>> elements,
    List<Map<String, dynamic>> recommendations,
  ) {
    // 查找可滚动元素
    final scrollable = elements.where((e) => e['isScrollable'] == true);

    if (scrollable.isNotEmpty) {
      recommendations.add({
        'name': '列表滚动测试',
        'description': '测试列表滚动功能',
        'actions': [
          ...scrollable.map((e) => {
            'actionType': 'swipe',
            'x1': e['centerX'] ?? 540,
            'y1': 1600,
            'x2': e['centerX'] ?? 540,
            'y2': 400,
            'durationMs': 300,
          }),
        ],
      });
    }

    // 查找列表项点击
    final clickable = elements.where((e) => e['isClickable'] == true);
    if (clickable.isNotEmpty) {
      recommendations.add({
        'name': '列表项点击测试',
        'description': '测试点击列表项',
        'actions': clickable.take(3).map((e) => {
          'actionType': 'click',
          'x': e['centerX'],
          'y': e['centerY'],
        }).toList(),
      });
    }
  }

  /// 推荐表单测试
  static void _addFormTest(
    List<Map<String, dynamic>> elements,
    List<Map<String, dynamic>> recommendations,
  ) {
    final editable = elements.where((e) => e['isEditable'] == true);
    final buttons = elements.where((e) => e['isClickable'] == true);

    if (editable.isNotEmpty) {
      recommendations.add({
        'name': '表单输入测试',
        'description': '测试表单输入功能',
        'actions': [
          ...editable.map((e) => {
            'actionType': 'input',
            'x': e['centerX'],
            'y': e['centerY'],
            'text': '测试输入',
          }),
          if (buttons.isNotEmpty)
            {
              'actionType': 'click',
              'x': buttons.first['centerX'],
              'y': buttons.first['centerY'],
            },
        ],
      });
    }
  }

  /// 推荐功能测试
  static void _addFunctionTest(
    List<Map<String, dynamic>> elements,
    List<Map<String, dynamic>> recommendations,
  ) {
    final clickable = elements.where((e) => e['isClickable'] == true);

    if (clickable.isNotEmpty) {
      recommendations.add({
        'name': '功能点击测试',
        'description': '测试主要功能按钮',
        'actions': clickable.take(5).map((e) => {
          'actionType': 'click',
          'x': e['centerX'],
          'y': e['centerY'],
        }).toList(),
      });
    }
  }

  /// 推荐基础测试
  static void _addBasicTest(
    List<Map<String, dynamic>> elements,
    List<Map<String, dynamic>> recommendations,
  ) {
    final clickable = elements.where((e) => e['isClickable'] == true);

    if (clickable.isNotEmpty) {
      recommendations.add({
        'name': '基础点击测试',
        'description': '测试可点击元素',
        'actions': clickable.take(3).map((e) => {
          'actionType': 'click',
          'x': e['centerX'],
          'y': e['centerY'],
        }).toList(),
      });
    }
  }

  /// 将推荐转换为 TestCase
  static TestCase toTestCase(
    Map<String, dynamic> recommendation,
    String targetPackage,
    String targetAppName,
  ) {
    final actions = (recommendation['actions'] as List<dynamic>)
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final action = entry.value as Map<String, dynamic>;
          return TestAction(
            id: 'action_$index',
            actionType: action['actionType'],
            x: action['x']?.toDouble(),
            y: action['y']?.toDouble(),
            endX: action['x2']?.toDouble(),
            endY: action['y2']?.toDouble(),
            text: action['text'],
            timestamp: DateTime.now().millisecondsSinceEpoch,
            durationMs: action['durationMs'],
          );
        })
        .toList();

    return TestCase(
      id: 'tc_${DateTime.now().millisecondsSinceEpoch}',
      name: recommendation['name'],
      description: recommendation['description'],
      targetAppPackage: targetPackage,
      targetAppName: targetAppName,
      actions: actions,
      createdAt: DateTime.now(),
    );
  }
}
