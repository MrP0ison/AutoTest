#!/usr/bin/env dart
// 生成示例Excel模板文件
// 运行方式：dart generate_template.dart

import 'package:excel/excel.dart';

void main() {
  final excel = Excel.createExcel();
  
  // 删除默认创建的Sheet1
  excel.delete('Sheet1');
  
  // 创建工作表
  final sheet = excel['测试用例模板'];
  
  // 表头
  final header = [
    '用例名称',
    '目标APP包名',
    '目标APP名称',
    '步骤',
    '操作类型',
    'X坐标',
    'Y坐标',
    '结束X',
    '结束Y',
    '输入文本',
    '元素标识',
    '等待(ms)',
    '持续(ms)',
    '备注',
  ];
  
  // 写入表头
  for (var col = 0; col < header.length; col++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(
      columnIndex: col,
      rowIndex: 0,
    ));
    cell.value = header[col];
    cell.cellStyle = CellStyle(
      bold: true,
      backgroundColorHex: '#CCCCCC',
    );
  }
  
  // 示例数据
  final examples = [
    [
      '登录功能测试',
      'com.example.app',
      '示例APP',
      '1',
      'click',
      '540',
      '960',
      '',
      '',
      '',
      '登录按钮',
      '1000',
      '',
      '点击登录按钮',
    ],
    [
      '',
      '',
      '',
      '2',
      'input',
      '',
      '',
      '',
      '',
      'testuser',
      '用户名输入框',
      '500',
      '',
      '输入用户名',
    ],
    [
      '',
      '',
      '',
      '3',
      'input',
      '',
      '',
      '',
      '',
      'password123',
      '密码输入框',
      '500',
      '',
      '输入密码',
    ],
    [
      '',
      '',
      '',
      '4',
      'click',
      '540',
      '1200',
      '',
      '',
      '',
      '确认登录按钮',
      '1000',
      '',
      '点击确认登录',
    ],
    [
      '',
      '',
      '',
      '5',
      'swipe',
      '540',
      '1600',
      '540',
      '400',
      '',
      '',
      '500',
      '300',
      '上滑查看内容',
    ],
  ];
  
  // 写入示例数据
  for (var row = 0; row < examples.length; row++) {
    for (var col = 0; col < examples[row].length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: col,
        rowIndex: row + 1,
      ));
      cell.value = examples[row][col];
    }
  }
  
  // 保存文件
  final fileBytes = excel.encode();
  if (fileBytes != null) {
    final file = File('test_case_template.xlsx');
    await file.writeAsBytes(fileBytes);
    print('模板已生成：${file.path}');
  }
}
