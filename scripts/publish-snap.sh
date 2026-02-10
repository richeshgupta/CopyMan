#!/bin/bash
set -euo pipefail

echo "📦 CopyMan Snap Publishing Script"
echo "=================================="
echo ""

cd "$(dirname "$0")/../copyman"

# Check if snapcraft is installed
if ! command -v snapcraft &> /dev/null; then
    echo "❌ snapcraft not found. Install with:"
    echo "   sudo snap install snapcraft --classic"
    exit 1
fi

# Check if logged in
if ! snapcraft whoami &> /dev/null; then
    echo "🔑 Please login to Snapcraft..."
    snapcraft login
fi

# Register name (if needed)
echo ""
echo "📝 Registering app name..."
if snapcraft register copyman 2>&1 | grep -q "already registered"; then
    echo "✅ Name 'copyman' already registered"
else
    echo "✅ Name 'copyman' registered successfully"
fi

# Build snap
echo ""
echo "🔨 Building snap package..."
echo "⏱️  This may take 10-30 minutes on first build..."
snapcraft clean
snapcraft

SNAP_FILE="copyman_0.1.0_amd64.snap"
if [ ! -f "$SNAP_FILE" ]; then
    echo "❌ Snap file not found: $SNAP_FILE"
    exit 1
fi

echo ""
echo "✅ Snap built successfully: $SNAP_FILE"
echo ""

# Ask to test locally
read -p "Do you want to test the snap locally first? (recommended) [Y/n]: " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "Installing snap locally..."
    sudo snap install "$SNAP_FILE" --dangerous
    echo ""
    echo "✅ Snap installed locally. Test it by running: copyman"
    echo ""
    read -p "Press Enter to continue with publishing after testing..."
fi

# Upload and publish
echo ""
echo "🚀 Uploading to Snap Store..."
snapcraft upload "$SNAP_FILE" --release=stable

echo ""
echo "✅ Published successfully! 🎉"
echo ""
echo "Your snap is now available at:"
echo "https://snapcraft.io/copyman"
echo ""
echo "Users can install with:"
echo "  sudo snap install copyman"
echo ""
echo "Next steps:"
echo "  1. Wait 5-10 minutes for it to appear in the store"
echo "  2. Test installation: sudo snap install copyman"
echo "  3. Update your README with Snap Store badge"
echo "  4. Announce the Snap release!"
