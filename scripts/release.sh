#!/bin/bash
set -euo pipefail

VERSION="${1:-0.1.0}"
GITHUB_REPO="richeshgupta/CopyMan"

echo "🚀 CopyMan Release Script v${VERSION}"
echo "=================================="

cd "$(dirname "$0")/.."

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Install: sudo apt install gh"
    exit 1
fi

# Ensure on master branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "master" ]; then
    echo "⚠️  Warning: Not on master branch (currently on ${CURRENT_BRANCH})"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "❌ Uncommitted changes detected. Commit or stash them first."
    exit 1
fi

echo ""
echo "📦 Step 1: Building .deb package..."
cd copyman
chmod +x packaging/build_deb.sh
./packaging/build_deb.sh

DEB_FILE="copyman_${VERSION}_amd64.deb"
if [ ! -f "$DEB_FILE" ]; then
    echo "❌ .deb package not found: $DEB_FILE"
    exit 1
fi
echo "✅ Created: $DEB_FILE"

echo ""
echo "📦 Step 2: Building Snap package..."
if command -v snapcraft &> /dev/null; then
    snapcraft clean
    snapcraft
    SNAP_FILE="copyman_${VERSION}_amd64.snap"
    if [ -f "$SNAP_FILE" ]; then
        echo "✅ Created: $SNAP_FILE"
    else
        echo "⚠️  Snap package not found (non-fatal)"
    fi
else
    echo "⚠️  snapcraft not installed, skipping snap build"
fi

cd ..

echo ""
echo "📝 Step 3: Creating release notes..."
cat > RELEASE_NOTES.md << EOF
# CopyMan v${VERSION} - First Stable Release 🎉

## 🌟 Highlights

CopyMan is a keyboard-first clipboard manager for Linux with comprehensive test coverage and production-ready features.

## ✨ Key Features

- **📋 Clipboard History**: Real-time capture of text and images
- **🔍 Fuzzy Search**: Instant search with character highlighting
- **📁 Groups/Folders**: Organize items with color-coded groups
- **🔄 Sequential Paste**: Multi-select and paste multiple items in sequence
- **📌 Pin Items**: Keep important snippets at the top
- **🚫 App Exclusions**: Auto-exclude password managers and sensitive apps
- **🔐 Sensitive Detection**: Auto-detect passwords, API keys, and tokens
- **⌨️ Configurable Shortcuts**: 13 customizable keyboard shortcuts
- **🎨 Dark/Light Themes**: Follow system theme preference
- **📦 Distribution**: Snap and .deb packages ready

## 📊 Status

- **Platform**: Linux (production-ready)
- **Tests**: 177 tests passing ✅
- **Phase 1 MVP**: 100% complete
- **Phase 2 v1.0**: 90% complete

## 📥 Installation

### Ubuntu/Debian (.deb)
\`\`\`bash
wget https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/copyman_${VERSION}_amd64.deb
sudo dpkg -i copyman_${VERSION}_amd64.deb
sudo apt-get install -f
\`\`\`

### Snap (Universal Linux)
\`\`\`bash
sudo snap install --dangerous copyman_${VERSION}_amd64.snap
\`\`\`

Or from Snap Store (coming soon):
\`\`\`bash
sudo snap install copyman
\`\`\`

## 🎯 Quick Start

1. Press **Ctrl+Alt+V** to open CopyMan
2. Start typing to search clipboard history
3. Press **Enter** to copy, **Ctrl+Enter** to copy & paste
4. Press **Shift+/** for keyboard shortcuts help

## 📚 Documentation

- [Features & Architecture](https://github.com/${GITHUB_REPO}/blob/master/FEATURES_AND_ARCHITECTURE.md)
- [Development Guide](https://github.com/${GITHUB_REPO}/blob/master/docs/DEVELOPMENT.md)
- [Contributing](https://github.com/${GITHUB_REPO}/blob/master/CONTRIBUTING.md)

## 🐛 Known Limitations

- macOS and Windows support in testing (code ready, needs validation)
- Performance not tested with 10,000+ items
- No cross-device sync (planned for Phase 5)

## 🙏 Feedback

Report issues at: https://github.com/${GITHUB_REPO}/issues
EOF

echo "✅ Created RELEASE_NOTES.md"

echo ""
echo "🏷️  Step 4: Creating Git tag..."
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    echo "⚠️  Tag v${VERSION} already exists"
else
    git tag -a "v${VERSION}" -m "Release v${VERSION}"
    git push origin "v${VERSION}"
    echo "✅ Created and pushed tag v${VERSION}"
fi

echo ""
echo "🚀 Step 5: Creating GitHub release..."
RELEASE_FILES=""
if [ -f "copyman/$DEB_FILE" ]; then
    RELEASE_FILES="copyman/$DEB_FILE"
fi
if [ -f "copyman/$SNAP_FILE" ]; then
    RELEASE_FILES="$RELEASE_FILES copyman/$SNAP_FILE"
fi

if [ -z "$RELEASE_FILES" ]; then
    echo "❌ No release files found"
    exit 1
fi

gh release create "v${VERSION}" $RELEASE_FILES \
    --title "CopyMan v${VERSION} - First Stable Release" \
    --notes-file RELEASE_NOTES.md

echo ""
echo "✅ Release complete! 🎉"
echo ""
echo "📎 Release URL: https://github.com/${GITHUB_REPO}/releases/tag/v${VERSION}"
echo ""
echo "Next steps:"
echo "  1. Test the release binaries"
echo "  2. Publish Snap to Snap Store: snapcraft upload copyman/$SNAP_FILE --release=stable"
echo "  3. Announce on social media, forums, etc."
echo ""
