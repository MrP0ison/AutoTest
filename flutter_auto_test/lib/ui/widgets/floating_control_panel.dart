/// 悬浮窗控制面板 - 参考按键精灵设计
/// 通过 MethodChannel 控制原生悬浮窗
import 'package:flutter/services.dart';
import '../../features/recorder/recorder_engine.dart';

class FloatingControlPanel {
  static final FloatingControlPanel _instance = FloatingControlPanel._internal();
  factory FloatingControlPanel() => _instance;
  FloatingControlPanel._internal();

  final _channel = const MethodChannel('com.tencent.autotest/accessibility');
  final _recorder = RecorderEngine();
  
  bool _isVisible = false;
  bool get isVisible => _isVisible;

  /// 显示悬浮窗
  Future<void> show() async {
    try {
      await _channel.invokeMethod('showFloatingWindow');
      _isVisible = true;
      print('悬浮窗已显示');
    } catch (e) {
      print('显示悬浮窗失败: $e');
    }
  }

  /// 隐藏悬浮窗
  Future<void> hide() async {
    try {
      await _channel.invokeMethod('hideFloatingWindow');
      _isVisible = false;
      print('悬浮窗已隐藏');
    } catch (e) {
      print('隐藏悬浮窗失败: $e');
    }
  }

  /// 切换显示/隐藏
  Future<void> toggle() async {
    if (_isVisible) {
      await hide();
    } else {
      await show();
    }
  }

  /// 检查悬浮窗是否显示
  Future<bool> checkVisibility() async {
    try {
      final result = await _channel.invokeMethod('isFloatingWindowShowing');
      _isVisible = result == true;
      return _isVisible;
    } catch (e) {
      return false;
    }
  }
}
