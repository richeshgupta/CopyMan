#!/bin/bash
# Builds the release tarball consumed by arch/PKGBUILD.
# Upload the result to the GitHub release; this script updates arch/PKGBUILD (pkgver, sha256sums).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION="$(sed -n 's/^version: *\([0-9.]*\).*/\1/p' "$PROJECT_DIR/pubspec.yaml")"
TARBALL="copyman-${VERSION}-linux-x64.tar.gz"

cd "$PROJECT_DIR"

echo "Building Flutter release..."
flutter build linux --release

BUNDLE_DIR="build/linux/x64/release/bundle"
if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: Bundle not found at $BUNDLE_DIR"
  exit 1
fi

echo "Creating tarball..."
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
mkdir "$STAGE/copyman"
cp -r "$BUNDLE_DIR/"* "$STAGE/copyman/"
cp "$SCRIPT_DIR/copyman.desktop" "$STAGE/copyman/"
cp "$PROJECT_DIR/../LICENSE" "$STAGE/copyman/LICENSE"
cp "assets/icons/tray_icon.png" "$STAGE/copyman/copyman.png"
tar -C "$STAGE" -czf "$PROJECT_DIR/$TARBALL" copyman

echo "Created: $TARBALL"
SUM="$(sha256sum "$TARBALL" | cut -d" " -f1)"
echo "sha256: $SUM"
sed -i "s/^sha256sums=.*/sha256sums=('$SUM')/; s/^pkgver=.*/pkgver=$VERSION/" "$SCRIPT_DIR/arch/PKGBUILD"
echo "Updated arch/PKGBUILD (pkgver, sha256sums)."
