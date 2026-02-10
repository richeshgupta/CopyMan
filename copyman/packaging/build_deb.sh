#!/bin/bash
set -euo pipefail

APP_NAME="copyman"
VERSION="0.1.0"
ARCH="amd64"
PKG_DIR="${APP_NAME}_${VERSION}_${ARCH}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_DIR"

echo "Building Flutter release..."
flutter build linux --release

BUNDLE_DIR="build/linux/x64/release/bundle"
if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: Bundle not found at $BUNDLE_DIR"
  exit 1
fi

echo "Creating package structure..."
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR/DEBIAN"
mkdir -p "$PKG_DIR/usr/lib/$APP_NAME"
mkdir -p "$PKG_DIR/usr/bin"
mkdir -p "$PKG_DIR/usr/share/applications"
mkdir -p "$PKG_DIR/usr/share/icons/hicolor/256x256/apps"

# Control file
cat > "$PKG_DIR/DEBIAN/control" << EOF
Package: $APP_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: CopyMan Developers
Depends: libgtk-3-0, xclip, xdotool, x11-utils
Section: utils
Priority: optional
Description: Cross-platform clipboard manager
 CopyMan tracks your clipboard history, supports text and image content,
 and lets you quickly paste previous items using configurable keyboard shortcuts.
EOF

# Copy bundle
cp -r "$BUNDLE_DIR/"* "$PKG_DIR/usr/lib/$APP_NAME/"

# Wrapper script
cat > "$PKG_DIR/usr/bin/$APP_NAME" << 'EOF'
#!/bin/bash
exec /usr/lib/copyman/copyman "$@"
EOF
chmod 755 "$PKG_DIR/usr/bin/$APP_NAME"

# Desktop entry
cp "$SCRIPT_DIR/copyman.desktop" "$PKG_DIR/usr/share/applications/"

# Icon
cp "assets/icons/tray_icon.png" "$PKG_DIR/usr/share/icons/hicolor/256x256/apps/copyman.png"

echo "Building .deb package..."
dpkg-deb --build "$PKG_DIR"

rm -rf "$PKG_DIR"
echo "Package created: ${PKG_DIR}.deb"
