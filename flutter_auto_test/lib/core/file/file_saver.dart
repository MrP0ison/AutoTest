/// 文件保存工具 - 让用户选择保存位置并保存文件
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FileSaver {
  /// 保存文件，让用户选择保存位置
  /// 返回保存后的文件路径，失败返回 null
  static Future<String?> saveFile({
    required BuildContext context,
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: fileName,
      );

      if (result == null) return null; // 用户取消

      final file = File(result);
      await file.writeAsBytes(bytes);
      return result;
    } catch (e) {
      print('保存文件失败: $e');
      return null;
    }
  }

  /// 保存文本文件
  static Future<String?> saveTextFile({
    required BuildContext context,
    required String fileName,
    required String content,
  }) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存位置',
        fileName: fileName,
        allowedExtensions: ['txt', 'json', 'csv', 'xlsx', 'html'],
      );

      if (result == null) return null;

      final file = File(result);
      await file.writeAsString(content);
      return result;
    } catch (e) {
      print('保存文件失败: $e');
      return null;
    }
  }

  /// 打开文件（使用系统默认应用）
  static Future<void> openFile(String filePath) async {
    try {
      // Android 上使用 Intent 打开
      final result = await MethodChannel('com.tencent.autotest/file')
          .invokeMethod('openFile', {'path': filePath});
    } catch (e) {
      print('打开文件失败: $e');
    }
  }
}
