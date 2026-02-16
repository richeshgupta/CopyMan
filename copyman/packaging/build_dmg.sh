#!/bin/bash
set -euo pipefail

APP_NAME="CopyMan"
APP_NAME_LOWER="copyman"
VERSION="0.1.0"
DMG_NAME="${APP_NAME_LOWER}_${VERSION}_macos"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

if [ "$(uname)" != "Darwin" ]; then
    echo "Error: This script must be run on macOS"
    exit 1
fi

echo "Building Flutter macOS release..."
flutter build macos --release

APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not found at $APP_PATH"
    exit 1
fi

echo "Creating DMG..."
DMG_DIR=$(mktemp -d)
cp -r "$APP_PATH" "$DMG_DIR/"

# Create a symlink to /Applications for drag-and-drop install
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "${DMG_NAME}.dmg"

rm -rf "$DMG_DIR"
echo "Package created: ${DMG_NAME}.dmg"
