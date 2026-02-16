#!/bin/bash
set -euo pipefail

VERSION="${1:-0.1.0}"
GITHUB_REPO="richeshgupta/CopyMan"
OS="$(uname)"

echo "🚀 CopyMan Release Script v${VERSION}"
echo "=================================="
echo "Platform: ${OS}"

cd "$(dirname "$0")/.."

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found."
    if [ "$OS" = "Darwin" ]; then
        echo "   Install: brew install gh"
    else
        echo "   Install: sudo apt install gh"
    fi
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

RELEASE_FILES=""

cd copyman

# ── Linux packages ─────────────────────────────────────────────

if [ "$OS" = "Linux" ]; then
    echo ""
    echo "📦 Building .deb package..."
    chmod +x packaging/build_deb.sh
    ./packaging/build_deb.sh

    DEB_FILE="copyman_${VERSION}_amd64.deb"
    if [ -f "$DEB_FILE" ]; then
        echo "✅ Created: $DEB_FILE"
        RELEASE_FILES="copyman/$DEB_FILE"
    else
        echo "⚠️  .deb package not found (non-fatal)"
    fi

    echo ""
    echo "📦 Building Snap package..."
    SNAP_FILE="copyman_${VERSION}_amd64.snap"
    if command -v snapcraft &> /dev/null; then
        snapcraft clean
        snapcraft
        if [ -f "$SNAP_FILE" ]; then
            echo "✅ Created: $SNAP_FILE"
            RELEASE_FILES="$RELEASE_FILES copyman/$SNAP_FILE"
        else
            echo "⚠️  Snap package not found (non-fatal)"
        fi
    else
        echo "⚠️  snapcraft not installed, skipping snap build"
    fi
fi

# ── macOS package ──────────────────────────────────────────────

if [ "$OS" = "Darwin" ]; then
    echo ""
    echo "📦 Building macOS .dmg package..."
    chmod +x packaging/build_dmg.sh
    ./packaging/build_dmg.sh

    DMG_FILE="copyman_${VERSION}_macos.dmg"
    if [ -f "$DMG_FILE" ]; then
        echo "✅ Created: $DMG_FILE"
        RELEASE_FILES="copyman/$DMG_FILE"
    else
        echo "❌ .dmg package not found: $DMG_FILE"
        exit 1
    fi
fi

cd ..

# ── Release notes ──────────────────────────────────────────────

echo ""
echo "📝 Creating release notes..."
cat > RELEASE_NOTES.md << EOF
# CopyMan v${VERSION}

## Highlights

CopyMan is a keyboard-first clipboard manager for Linux and macOS with comprehensive test coverage and production-ready features.

## Key Features

- **Clipboard History**: Real-time capture of text and images (500ms polling)
- **Fuzzy Search**: Instant search with character highlighting
- **Groups/Folders**: Organize items with color-coded groups
- **Sequential Paste**: Multi-select and paste multiple items in sequence
- **Pin Items**: Keep important snippets at the top
- **App Exclusions**: Auto-exclude password managers and sensitive apps
- **Sensitive Detection**: Auto-detect passwords, API keys, and tokens
- **Configurable Shortcuts**: 13 customizable keyboard shortcuts
- **Dark/Light Themes**: Follow system theme preference

## Status

- **Linux**: Production-ready
- **macOS**: Supported (osascript-based clipboard, paste, app detection)
- **Tests**: 177 tests passing
- **Phase 1 MVP**: 100% complete
- **Phase 2 v1.0**: 90% complete

## Installation

### Linux (Ubuntu/Debian)
\`\`\`bash
curl -sSL https://raw.githubusercontent.com/${GITHUB_REPO}/master/install.sh | bash
\`\`\`

Or download the .deb directly:
\`\`\`bash
wget https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/copyman_${VERSION}_amd64.deb
sudo dpkg -i copyman_${VERSION}_amd64.deb
sudo apt-get install -f
\`\`\`

### macOS
1. Download \`copyman_${VERSION}_macos.dmg\` from this release
2. Open the DMG and drag **CopyMan** to **Applications**
3. On first launch, grant Accessibility permissions when prompted

## Quick Start

1. Press **Ctrl+Alt+V** (Linux) or **Control+Option+V** (macOS) to open CopyMan
2. Start typing to search clipboard history
3. Press **Enter** to copy, **Ctrl+Enter** / **Control+Enter** to copy & paste
4. Press **Shift+/** for keyboard shortcuts help

## Feedback

Report issues at: https://github.com/${GITHUB_REPO}/issues
EOF

echo "✅ Created RELEASE_NOTES.md"

# ── Git tag ────────────────────────────────────────────────────

echo ""
echo "🏷️  Creating Git tag..."
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    echo "⚠️  Tag v${VERSION} already exists"
else
    git tag -a "v${VERSION}" -m "Release v${VERSION}"
    git push origin "v${VERSION}"
    echo "✅ Created and pushed tag v${VERSION}"
fi

# ── GitHub release ─────────────────────────────────────────────

echo ""
echo "🚀 Creating GitHub release..."

if [ -z "$RELEASE_FILES" ]; then
    echo "❌ No release files found"
    exit 1
fi

# Trim leading whitespace from RELEASE_FILES
RELEASE_FILES=$(echo "$RELEASE_FILES" | xargs)

gh release create "v${VERSION}" $RELEASE_FILES \
    --title "CopyMan v${VERSION}" \
    --notes-file RELEASE_NOTES.md

echo ""
echo "✅ Release complete! 🎉"
echo ""
echo "📎 Release URL: https://github.com/${GITHUB_REPO}/releases/tag/v${VERSION}"
echo ""
echo "Next steps:"
echo "  1. Test the release binaries"
if [ "$OS" = "Linux" ]; then
    echo "  2. Publish Snap: snapcraft upload copyman/copyman_${VERSION}_amd64.snap --release=stable"
fi
if [ "$OS" = "Darwin" ]; then
    echo "  2. Test the .dmg on a clean macOS system"
    echo "  3. Consider code-signing and notarization for Gatekeeper"
fi
echo ""
