#!/bin/bash

# CopyMan Development Runner with Xvfb (Virtual Display)
# For headless environments (SSH, servers, Docker)

echo "Starting CopyMan with Xvfb (virtual display)..."

# Check if xvfb is installed
if ! command -v xvfb-run &> /dev/null; then
    echo "ERROR: Xvfb is not installed!"
    echo ""
    echo "Install with:"
    echo "  sudo apt install xvfb"
    echo ""
    echo "Or use software rendering instead:"
    echo "  ./run-dev.sh"
    exit 1
fi

echo "Xvfb found, starting virtual display..."

# Run with Xvfb
# -a: automatically pick available display number
# -s: server arguments (screen resolution and color depth)
xvfb-run -a -s "-screen 0 1024x768x24" npm run tauri dev
