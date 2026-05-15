# AutoTest - Flutter 自动化测试 Android APP

> 腾讯内部 QA 工具，支持录制/回放测试用例、性能数据采集、无障碍自动化。
> **版本**：v2.0 Final  
> **构建日期**：2026-05-15  
> **Flutter 版本**：3.41.9  
> **Dart SDK**：>=3.0.0 <4.0.0  

---

## 功能列表

| # | 功能 | 状态 | 说明 |
|---|---|---|---|
| 1 | 原生无障碍事件采集 | ✅ 完成 | `AutoTestAccessibilityService.kt` 实现点击/长按/滑动/输入/返回 |
| 2 | Workmanager 兼容性 | ✅ 完成 | 改用 `Timer.periodic` 采集性能数据 |
| 3 | 性能测试：CPU / 内存 / FPS | ✅ 完成 | `performance_monitor.dart` + MethodChannel |
| 4 | 性能测试：功耗 / 电池 | ✅ 完成 | `powerMw`, `batteryCurrentMa`, `batteryMah` |
| 5 | 性能测试：网络流量 | ✅ 完成 | `networkSentKb`, `networkRecvKb`, `networkType` |
| 6 | 性能图表可视化 | ✅ 完成 | `performance_chart_page.dart`，`fl_chart` 三 Tab |
| 7 | 多账号管理 | ✅ 完成 | `accounts_page.dart`，CRUD + JSON 持久化 |
| 8 | 测试用例导入 | ✅ 完成 | `import_page.dart`，支持 JSON / CSV |
| 9 | 目标 APP 选择 | ✅ 完成 | `app_selector_page.dart`，调用 `getInstalledApps` |
| 10 | 授权管理（Root/ADB/无障碍） | ✅ 完成 | `auth_manager.dart`，自适应降级 |
| 11 | 预期性能指标对比 | ✅ 完成 | `settings_page.dart`，`shared_preferences` 存储 |
| 12 | 报告生成（功能 + 性能 + CSV） | ✅ 完成 | `report_generator.dart` |

---

## 工程结构

```
flutter_auto_test/
├── lib/
│   ├── main.dart                          # 入口，路由配置
│   ├── models/
│   │   ├── test_case.dart               # 测试用例模型
│   │   ├── test_action.dart            # 测试动作模型
│   │   ├── test_report.dart           # 测试报告模型
│   │   └── performance_data.dart      # 性能数据模型
│   ├── core/
│   │   ├── auth_manager/
│   │   │   └── auth_manager.dart      # 授权管理（Root/ADB/无障碍）
│   │   ├── performance_monitor/
│   │   │   └── performance_monitor.dart  # 性能采集（MethodChannel）
│   │   └── report_generator/
│   │       └── report_generator.dart  # 报告生成（功能/性能/CSV）
│   ├── features/
│   │   ├── recorder/
│   │   │   └── recorder_engine.dart   # 录制引擎
│   │   └── player/
│   │       └── player_engine.dart     # 回放引擎 + 报告生成
│   └── ui/
│       └── pages/
│           ├── home_page.dart          # 首页（授权状态 + 功能入口）
│           ├── recorder_page.dart       # 录制页面
│           ├── player_page.dart        # 回放页面
│           ├── reports_page.dart       # 测试报告列表（跳转图表）
│           ├── performance_chart_page.dart  # 性能图表（3 Tab）
│           ├── accounts_page.dart      # 多账号管理
│           ├── settings_page.dart      # 预期性能指标设置
│           ├── import_page.dart       # 导入测试用例
│           └── app_selector_page.dart  # 目标 APP 选择
├── android/
│   └── app/
│       └── src/main/
│           └── kotlin/com/tencent/autotest/flutter_auto_test/
│               ├── MainActivity.kt            # FlutterEngine + MethodChannel
│               └── AutoTestAccessibilityService.kt  # 无障碍服务（手势执行）
└── pubspec.yaml
```

---

## 构建命令

```bash
# 调试版
flutter build apk --debug

# 发布版（需配置签名）
flutter build apk --release
```

**输出路径**：
- Debug APK：`build/app/outputs/flutter-apk/app-debug.apk`
- Release APK：`build/app/outputs/flutter-apk/app-release.apk`

---

## 安装方式

```bash
adb install app-debug.apk
```

---

## 已发布的 APK

| 版本 | 路径 | 大小 | 说明 |
|---|---|---|---|
| v2.0 Final | [GitHub Release v2.0](https://github.com/MrPison/AutoTest/releases/tag/v2.0) | 169 MB | Debug 版，完整功能 |

---

## 待迭代（P2）

1. **MSDK v3/v5 支持**（低优先级）
2. **腾讯游戏优化**（自动处理弹窗、识别游戏引擎）
3. **Release APK 签名配置**
4. **非 Root 设备网络统计降级方案**（`TrafficStats.getUidRx/TxBytes`）
5. **`AutoTestAccessibilityService.kt` 完整 `GestureDescription` 回调**（当前为简化版）

---

## 技术要点

### 授权降级策略
```
Root（su -c） → ADB（adb shell） → 无障碍服务（Adaptive Degradation）
```

### 性能采集架构
```
Flutter（Dart） → MethodChannel → Android（Kotlin） → sysfs / dumpsys
```

### 关键文件
- **`MainActivity.kt`**：实现 `ACCESSIBILITY_CHANNEL` + `PERFORMANCE_CHANNEL`
- **`AutoTestAccessibilityService.kt`**：处理无障碍事件 + 执行手势
- **`performance_monitor.dart`**：每秒采集一次性能数据（Timer.periodic）
- **`report_generator.dart`**：对比预期指标，生成 ✅/❌ 报告

---

## 任务记录（本次迭代）

### 第一轮：基础框架搭建
- Flutter 3.41.9 环境配置
- 工程创建（`flutter create --platforms android`）
- `pubspec.yaml` 依赖配置（`fl_chart`, `file_picker`, `shared_preferences` 等）

### 第二轮：功能 1 + 2 + 5 迭代
- **Feature 1**：`AutoTestAccessibilityService.kt` 手势执行实现
- **Feature 2**：移除 `workmanager`，改用 `Timer.periodic`
- **Feature 5**：功耗 + 网络指标采集

### 第三轮：空壳代码实现
- `auth_manager.dart`：`_checkAccessibility()` 通过 MethodChannel 实现
- `settings_page.dart`：保存/加载预期指标到 `SharedPreferences`
- `accounts_page.dart`：修复类型转换错误
- `reports_page.dart`：点击 JSON 报告跳转到性能图表页
- `player_engine.dart`：回放时生成功能报告 + 性能报告
- `performance_chart_page.dart`：补充 `dart:convert` 导入

### 第四轮：GitHub 推送
- 创建仓库 `https://github.com/MrPison/AutoTest`
- 推送完整工程源码（排除 APK，因 GitHub 100MB 限制）
- 上传 APK 到 GitHub Release（v2.0）
- 生成本文档并推送

---

## 作者

MrPison · Tencent QA Engineer · 2026-05-15
