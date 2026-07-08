#!/bin/bash

# Build script for Translator macOS app
# Usage:
#   ./build.sh          - Build the .app bundle (Release)
#   ./build.sh dmg      - Build and package into a .dmg

set -e

APP_NAME="Translator"
SCHEME="Translator"
PROJECT="Translator.xcodeproj"
BUILD_DIR="build"
APP_PATH="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
DMG_TEMP="$BUILD_DIR/dmg_temp"

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "🔨 Building $APP_NAME (Release)..."

# Build the app with xcodebuild
xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    archive \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=YES \
    2>&1 | tail -5

# Export the archive to .app
xcodebuild -exportArchive \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    -exportOptionsPlist exportOptions.plist \
    -exportPath "$BUILD_DIR/export" \
    2>&1 | tail -5

# Move .app to build root
mv "$BUILD_DIR/export/$APP_NAME.app" "$APP_PATH"

echo "✅ Built: $APP_PATH"

# If "dmg" argument passed, create DMG
if [ "$1" = "dmg" ]; then
    echo ""
    echo "📦 Creating DMG..."

    # Prepare DMG staging folder
    rm -rf "$DMG_TEMP"
    mkdir -p "$DMG_TEMP"
    cp -R "$APP_PATH" "$DMG_TEMP/"
    ln -s /Applications "$DMG_TEMP/Applications"

    # Create DMG
    rm -f "$DMG_PATH"
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$DMG_TEMP" \
        -ov -format UDZO \
        "$DMG_PATH"

    # Cleanup
    rm -rf "$DMG_TEMP"

    echo "✅ DMG created: $DMG_PATH"
    echo ""
    echo "📏 Size: $(du -h "$DMG_PATH" | cut -f1)"
fi

echo ""
echo "Done!"
