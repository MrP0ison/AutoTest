/// 授权管理模块 - 自适应降级：Root → ADB → 无障碍
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

enum AuthMethod { root, adb, accessibility, none }

enum AuthStatus { granted, denied, notDetermined }

class AuthState {
  final AuthMethod activeMethod;
  final AuthStatus status;
  final String description;

  AuthState({
    this.activeMethod = AuthMethod.none,
    this.status = AuthStatus.notDetermined,
    this.description = '未授权',
  });

  bool get isReady => status == AuthStatus.granted;
}

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  final _channel = const MethodChannel('com.tencent.autotest/accessibility');

  AuthState _state = AuthState();
  AuthState get state => _state;

  /// 检测当前可用的授权方式（优先级：Root > ADB > 无障碍）
  Future<AuthState> detectAuth() async {
    // 1. 检测 Root
    if (await _checkRoot()) {
      _state = AuthState(
        activeMethod: AuthMethod.root,
        status: AuthStatus.granted,
        description: 'Root 权限已获取',
      );
      return _state;
    }

    // 2. 检测 ADB 授权（通过执行 adb shell 命令验证）
    if (await _checkAdb()) {
      _state = AuthState(
        activeMethod: AuthMethod.adb,
        status: AuthStatus.granted,
        description: 'ADB 授权已获取',
      );
      return _state;
    }

    // 3. 检测无障碍服务是否开启（通过 MethodChannel）
    if (await _checkAccessibility()) {
      _state = AuthState(
        activeMethod: AuthMethod.accessibility,
        status: AuthStatus.granted,
        description: '无障碍服务已开启',
      );
      return _state;
    }

    _state = AuthState(
      activeMethod: AuthMethod.none,
      status: AuthStatus.denied,
      description: '请授权：开启 Root，或在电脑上运行 adb，或开启无障碍服务',
    );
    return _state;
  }

  Future<bool> _checkRoot() async {
    try {
      final result = await Process.run('su', ['-c', 'echo root_test']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkAdb() async {
    try {
      final result = await Process.run('adb', ['shell', 'echo', 'adb_test']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkAccessibility() async {
    try {
      final result = await _channel.invokeMethod('isAccessibilityServiceEnabled');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// 打开无障碍设置页（通过 MethodChannel 调用原生）
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  /// 执行 Shell 命令（根据当前授权方式自适应）
  Future<ProcessResult> execCommand(List<String> command) async {
    switch (_state.activeMethod) {
      case AuthMethod.root:
        return Process.run('su', ['-c', command.join(' ')]);
      case AuthMethod.adb:
        return Process.run('adb', ['shell', ...command]);
      case AuthMethod.accessibility:
        throw Exception('无障碍模式不支持 Shell 命令，请使用无障碍 API');
      case AuthMethod.none:
        throw Exception('未授权，无法执行命令');
    }
  }
}
