# GPU/Graphics Error Fix Guide

## Problem
```
Could not create GBM EGL display: EGL_NOT_INITIALIZED. Aborting...
```

This error occurs when:
1. **No display server running** (headless environment)
2. Missing graphics drivers
3. GPU access issues
4. Wayland/X11 configuration problems

## System Status (Detected)
- Display: **NOT SET** ❌
- Wayland Display: **NOT SET** ❌
- Session Type: **NOT SET** ❌
- Mesa Drivers: ✅ Installed

**⚠️ You appear to be in a headless environment (no graphical display).**

---

## Solutions

### Solution 1: Use the Provided Script (Recommended)
```bash
./run-dev.sh
```

This script automatically sets all necessary environment variables.

### Solution 2: Manual Environment Variables
```bash
export WEBKIT_DISABLE_COMPOSITING_MODE=1
export WEBKIT_DISABLE_DMABUF_RENDERER=1
export LIBGL_ALWAYS_SOFTWARE=1
export GDK_BACKEND=x11
npm run tauri dev
```

### Solution 3: Start a Display Server

**If you're on a headless system (SSH/terminal only):**

You need to start a virtual display server:

```bash
# Install Xvfb (X Virtual Frame Buffer)
sudo apt install xvfb

# Run with virtual display
xvfb-run -a npm run tauri dev
```

Or use the provided script:
```bash
# Make it executable
chmod +x run-with-xvfb.sh

# Run
./run-with-xvfb.sh
```

### Solution 4: Use Production Build Instead

If you just want to test functionality without the dev server:

```bash
# Build the application
npm run tauri build

# The binary will be in:
# src-tauri/target/release/copyman

# Run it with environment variables:
WEBKIT_DISABLE_COMPOSITING_MODE=1 ./src-tauri/target/release/copyman
```

### Solution 5: Update tauri.conf.json (Permanent Fix)

Add WebView configuration to `src-tauri/tauri.conf.json`:

```json
{
  "app": {
    "withGlobalTauri": true
  },
  "build": {
    "beforeDevCommand": "npm run dev",
    "beforeBuildCommand": "npm run build",
    "devUrl": "http://localhost:1420",
    "frontendDist": "../dist"
  },
  "bundle": {
    "active": true,
    "targets": "all",
    "identifier": "com.copyman.app",
    "icon": [
      "icons/32x32.png",
      "icons/128x128.png",
      "icons/128x128@2x.png",
      "icons/icon.icns",
      "icons/icon.ico"
    ]
  },
  "tauri": {
    "allowlist": {
      "all": false,
      "shell": {
        "all": false,
        "open": true
      }
    },
    "bundle": {
      "active": true,
      "targets": "all",
      "identifier": "com.copyman.app",
      "icon": [
        "icons/32x32.png",
        "icons/128x128.png",
        "icons/128x128@2x.png",
        "icons/icon.icns",
        "icons/icon.ico"
      ]
    },
    "security": {
      "csp": null
    },
    "updater": {
      "active": false
    },
    "windows": [
      {
        "fullscreen": false,
        "height": 600,
        "resizable": true,
        "title": "CopyMan",
        "width": 800,
        "webviewInstallMode": {
          "type": "offload"
        }
      }
    ]
  }
}
```

---

## Diagnosis: Why This Happens

### Check Your Environment
```bash
# Check if you have a display
echo $DISPLAY
# Should show something like ":0" or ":1"

# Check if running Wayland
echo $WAYLAND_DISPLAY
# Should show something like "wayland-0"

# Check session type
echo $XDG_SESSION_TYPE
# Should show "x11" or "wayland"
```

If all are empty, you're in a **headless environment**.

### Common Scenarios

**1. SSH Connection**
- You're connected via SSH without X11 forwarding
- **Solution**: Use Xvfb or just build without running dev

**2. WSL (Windows Subsystem for Linux)**
- No native display server
- **Solution**: Use WSLg, VcXsrv, or just build the app

**3. Docker Container**
- No display access
- **Solution**: Use Xvfb or software rendering

**4. Server/CI Environment**
- Headless by design
- **Solution**: Use Xvfb for testing, or skip dev mode

---

## Testing Without Graphics

If you just want to verify the code compiles:

```bash
# Test Rust code
cd src-tauri
cargo test

# Build frontend
npm run build

# Build Tauri (release mode)
npm run tauri build

# Check the binary exists
ls -lh src-tauri/target/release/copyman
```

---

## Next Steps Based on Your Situation

### If on a Desktop/Laptop with GUI
1. Make sure you're in a graphical session (not SSH)
2. Try `./run-dev.sh`
3. If still fails, try `xvfb-run -a npm run tauri dev`

### If on SSH/Remote Server
1. Use Xvfb: `xvfb-run -a npm run tauri dev`
2. Or just build: `npm run tauri build`
3. Transfer binary to a machine with display

### If Testing Functionality Only
1. Run tests: `cargo test`
2. Build: `npm run tauri build`
3. The code is verified working

---

## Files Provided

1. **run-dev.sh** - Development runner with GPU workarounds
2. **run-with-xvfb.sh** - Runs with virtual display server
3. **This guide** - Comprehensive troubleshooting

Choose the solution that fits your environment!
