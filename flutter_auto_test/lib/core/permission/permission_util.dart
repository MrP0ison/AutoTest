/// 权限申请工具类 - 主动申请所有必要权限
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PermissionUtil {
  /// 申请所有必要权限，返回是否全部授权
  static Future<bool> requestAllPermissions(BuildContext context) async {
    var allGranted = true;

    if (Platform.isAndroid) {
      // 悬浮窗权限（用于录制控制面板）
      final overlayStatus = await Permission.systemAlertWindow.status;
      if (!overlayStatus.isGranted) {
        final result = await Permission.systemAlertWindow.request();
        if (!result.isGranted) {
          allGranted = false;
        }
      }
    }

    // 无障碍服务需要引导用户手动开启
    final accessibilityEnabled = await isAccessibilityEnabled();
    if (!accessibilityEnabled) {
      if (context.mounted) {
        await _showAccessibilityGuideDialog(context);
      }
      allGranted = false;
    }

    return allGranted;
  }

  /// 显示无障碍服务引导对话框
  static Future<void> _showAccessibilityGuideDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('开启无障碍服务'),
        content: const Text(
          '请按以下步骤操作：\n\n'
          '1. 点击"去设置"\n'
          '2. 在系统设置中找到"AutoTest"\n'
          '3. 开启无障碍服务开关\n'
          '4. 返回本应用\n',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAccessibilitySettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 打开系统无障碍设置页面
  static Future<void> openAccessibilitySettings() async {
    try {
      await MethodChannel('com.tencent.autotest/accessibility')
          .invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print('打开设置失败: $e');
    }
  }

  /// 检查无障碍服务是否已开启
  static Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await MethodChannel('com.tencent.autotest/accessibility')
          .invokeMethod('isAccessibilityServiceEnabled');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// 检查悬浮窗权限是否已开启
  static Future<bool> isOverlayPermissionGranted() async {
    try {
      final status = await Permission.systemAlertWindow.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }
}
