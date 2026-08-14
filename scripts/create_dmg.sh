#!/bin/bash
set -e

echo "🔨 Packaging WinMac release DMG..."
./scripts/package_app.sh

DMG_NAME="build/WinMac.dmg"
DMG_DIR="build/dmg_temp"

rm -rf "$DMG_DIR" "$DMG_NAME"
mkdir -p "$DMG_DIR"

# Copy App to staging
cp -R build/WinMac.app "$DMG_DIR/"

# Create symlink to /Applications
ln -s /Applications "$DMG_DIR/Applications"

# Create compressed DMG
hdiutil create -volname "WinMac" -srcfolder "$DMG_DIR" -ov -format UDZO "$DMG_NAME"
rm -rf "$DMG_DIR"

echo "🎉 WinMac.dmg successfully created at $DMG_NAME!"
