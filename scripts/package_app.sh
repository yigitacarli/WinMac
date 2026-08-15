#!/bin/bash
set -e

echo "🔨 Building WinMac (Release Mode)..."
swift build -c release

APP_DIR="build/WinMac.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Creating .app bundle structure in $APP_DIR..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp .build/release/WinMac "$MACOS_DIR/WinMac"
chmod +x "$MACOS_DIR/WinMac"

# Copy Info.plist and Icon
cp Resources/Info.plist "$CONTENTS_DIR/Info.plist"
if [ -f "Resources/AppIcon.icns" ]; then
    cp Resources/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
fi

# Code sign with ad-hoc signature
echo "✍️ Ad-hoc code signing WinMac.app..."
codesign --force --deep --sign - --entitlements Resources/WinMac.entitlements "$APP_DIR"

# Install to /Applications
echo "🚀 Installing WinMac.app to /Applications..."
rm -rf /Applications/WinMac.app
cp -R "$APP_DIR" /Applications/WinMac.app

echo "✅ Successfully built, signed, and installed /Applications/WinMac.app!"
