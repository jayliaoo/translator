#!/bin/bash
set -euo pipefail

# 构建 Translator.app（绕过 xcodebuild 的 SWBBuildService 死锁问题）

APP_NAME="Translator"
BUILD_DIR="build/Release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
RESOURCES="$CONTENTS/Resources"
SOURCES=$(find Translator -name "*.swift" | sort)

ASSET_CATALOG="Translator/Resources/Assets.xcassets"
ASSET_OUT="/tmp/translator-actool-$$"

echo "🔨 编译 Swift 源文件..."
rm -rf "$APP_BUNDLE" 2>/dev/null

# 先编译资源（在 .app bundle 创建之前，避免 actool 缓存被干扰）
echo "🎨 编译资源（Assets.xcassets → Assets.car + AppIcon.icns）..."
rm -rf "$ASSET_OUT"
mkdir -p "$ASSET_OUT"
xcrun actool --compile "$ASSET_OUT" \
  --platform macosx \
  --minimum-deployment-target 14.0 \
  --app-icon AppIcon \
  --errors \
  --output-partial-info-plist "$ASSET_OUT/info.plist" \
  "$ASSET_CATALOG"

# 校验 actool 产出
if [ ! -f "$ASSET_OUT/Assets.car" ]; then
  echo "❌ actool 未产出 Assets.car,输出目录内容:"
  ls -la "$ASSET_OUT"
  exit 1
fi

mkdir -p "$CONTENTS/MacOS"
mkdir -p "$RESOURCES"

swiftc \
  -sdk "$(xcrun --show-sdk-path)" \
  -target arm64-apple-macos14.0 \
  -O \
  -module-name "$APP_NAME" \
  -o "$CONTENTS/MacOS/$APP_NAME" \
  $SOURCES

# 把编译产物搬到 .app bundle
cp "$ASSET_OUT/Assets.car" "$RESOURCES/"
[ -f "$ASSET_OUT/AppIcon.icns" ] && cp "$ASSET_OUT/AppIcon.icns" "$RESOURCES/"
rm -rf "$ASSET_OUT"

echo "📦 组装 Info.plist（合并图标字段）..."
cp Translator/Info.plist "$CONTENTS/"
# 把 actool 产出的 CFBundleIconFile / CFBundleIconName 合到 Info.plist
# 用 AppIcon（对应 asset catalog 里的 AppIcon.appiconset，也是 actool 产出的 icns 文件名）
plutil -replace CFBundleIconFile -string "AppIcon" "$CONTENTS/Info.plist"
plutil -insert CFBundleIconName -string "AppIcon" "$CONTENTS/Info.plist"

echo "🔏 Ad-hoc 签名..."
codesign --force --sign - \
  --entitlements Translator/Translator.entitlements \
  "$APP_BUNDLE"

echo ""
echo "✅ 构建完成: $APP_BUNDLE"
echo "   大小: $(du -sh "$APP_BUNDLE" | cut -f1)"
echo "   资源:"
ls -la "$RESOURCES/" | grep -v "^total" | awk '{print "     " $NF " (" $5 " bytes)"}'

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
