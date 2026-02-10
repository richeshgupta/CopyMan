#!/bin/bash
# CopyMan - Quick Installer for Debian/Ubuntu
set -e

VERSION="0.1.0"
PACKAGE="copyman_${VERSION}_amd64.deb"
URL="https://github.com/richeshgupta/CopyMan/releases/download/v${VERSION}/${PACKAGE}"

echo "📦 CopyMan Installer"
echo "===================="
echo ""
echo "Installing CopyMan v${VERSION}..."
echo ""

# Check if running on Debian/Ubuntu
if ! command -v dpkg &> /dev/null; then
    echo "❌ This installer is for Debian/Ubuntu systems only."
    echo "   For other distros, download from:"
    echo "   https://github.com/richeshgupta/CopyMan/releases"
    exit 1
fi

# Download
echo "📥 Downloading package..."
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

if command -v wget &> /dev/null; then
    wget -q --show-progress "$URL"
elif command -v curl &> /dev/null; then
    curl -L -o "$PACKAGE" "$URL"
else
    echo "❌ Neither wget nor curl found. Please install one of them."
    exit 1
fi

# Install
echo ""
echo "🔧 Installing package..."
echo "   (You may be prompted for your password)"
sudo dpkg -i "$PACKAGE"

# Fix dependencies if needed
if [ $? -ne 0 ]; then
    echo "📦 Installing dependencies..."
    sudo apt-get install -f -y
fi

# Cleanup
cd /
rm -rf "$TMP_DIR"

echo ""
echo "✅ CopyMan installed successfully! 🎉"
echo ""
echo "🎯 Quick Start:"
echo "   • Press Ctrl+Alt+V to open CopyMan"
echo "   • Start typing to search clipboard history"
echo "   • Press Shift+/ for keyboard shortcuts help"
echo ""
echo "📚 Documentation: https://github.com/richeshgupta/CopyMan"
echo "🐛 Report issues: https://github.com/richeshgupta/CopyMan/issues"
echo ""
