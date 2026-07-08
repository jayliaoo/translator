#!/bin/bash
set -euo pipefail

# 构建 Translator.app（绕过 xcodebuild 的 SWBBuildService 死锁问题）

APP_NAME="Translator"
BUILD_DIR="build/Release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
SOURCES=$(find Translator -name "*.swift" | sort)

echo "🔨 编译 Swift 源文件..."
rm -rf "$APP_BUNDLE" 2>/dev/null
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

swiftc \
  -sdk "$(xcrun --show-sdk-path)" \
  -target arm64-apple-macos14.0 \
  -O \
  -module-name "$APP_NAME" \
  -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
  $SOURCES

echo "📦 打包 .app bundle..."
cp Translator/Info.plist "$APP_BUNDLE/Contents/"

echo "🔏 Ad-hoc 签名..."
codesign --force --sign - \
  --entitlements Translator/Translator.entitlements \
  "$APP_BUNDLE"

echo ""
echo "✅ 构建完成: $APP_BUNDLE"
echo "   大小: $(du -sh "$APP_BUNDLE" | cut -f1)"

# 可选：打包为 .dmg
if [ "${1:-}" = "--dmg" ]; then
  echo ""
  echo "💿 创建 .dmg..."
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$APP_BUNDLE" \
    -ov -format UDZO \
    "$BUILD_DIR/$APP_NAME.dmg"
  echo "✅ DMG: $BUILD_DIR/$APP_NAME.dmg"
fi
