#!/bin/bash
# AutoTest 版本发布脚本
# 用法：./release.sh <版本号> <描述>
# 示例：./release.sh "2.2.0" "新增定时任务功能"

set -e

VERSION=$1
DESCRIPTION=$2

if [ -z "$VERSION" ]; then
  echo "❌ 请提供版本号"
  echo "用法：./release.sh <版本号> <描述>"
  echo "示例：./release.sh "2.2.0" "新增定时任务功能""
  exit 1
fi

if [ -z "$DESCRIPTION" ]; then
  echo "❌ 请提供版本描述"
  echo "用法：./release.sh <版本号> <描述>"
  exit 1
fi

echo "📦 开始发布 V$VERSION ..."

# 1. 更新 pubspec.yaml 版本号
echo "  正在更新版本号..."
cd "$(dirname "$0")"
sed -i "s/^version: .*/version: $VERSION/" pubspec.yaml

# 2. 构建 APK
echo "  正在构建 APK..."
flutter build apk --release

# 3. 生成版本说明
CHANGELOG="release_notes_v${VERSION//./}.md"
cat > "$CHANGELOG" << EOF
# AutoTest V$VERSION 版本说明

## 更新内容
$DESCRIPTION

## APK 下载
- \`build/app/outputs/flutter-apk/app-release.apk\`

## 安装说明
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 权限配置
1. 无障碍服务：设置 → 无障碍 → AutoTest → 开启
2. 悬浮窗权限：设置 → 应用管理 → AutoTest → 悬浮窗 → 允许
3. 存储权限：同上 → 存储权限 → 允许

---
版本：$VERSION  
发布时间：$(date '+%Y-%m-%d %H:%M:%S')
EOF

echo "  ✅ 版本说明已生成：$CHANGELOG"

# 4. Git 提交并推送
echo "  正在提交到 Git..."
git add -A
git commit -m "V$VERSION 版本发布

$DESCRIPTION

版本号：$VERSION
APK：build/app/outputs/flutter-apk/app-release.apk"

git push origin main

echo "✅ V$VERSION 发布完成！"
echo "   APK 路径：build/app/outputs/flutter-apk/app-release.apk"
echo "   版本说明：$CHANGELOG"
