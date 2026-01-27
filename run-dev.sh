#!/bin/bash

# CopyMan Development Runner with GPU workarounds
# Fixes: GBM EGL display errors on Linux

echo "Starting CopyMan in development mode with GPU workarounds..."

# Solution 1: Software rendering (fastest fix)
export WEBKIT_DISABLE_COMPOSITING_MODE=1
export WEBKIT_DISABLE_DMABUF_RENDERER=1

# Solution 2: Force software GL
export LIBGL_ALWAYS_SOFTWARE=1

# Solution 3: Additional WebKit fixes (only if absolutely necessary)
# export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1

# Solution 4: GDK backend (try X11 if on Wayland)
export GDK_BACKEND=x11

echo "Environment variables set:"
echo "  WEBKIT_DISABLE_COMPOSITING_MODE=1"
echo "  WEBKIT_DISABLE_DMABUF_RENDERER=1"
echo "  LIBGL_ALWAYS_SOFTWARE=1"
echo "  GDK_BACKEND=x11"
echo ""

npm run tauri dev
