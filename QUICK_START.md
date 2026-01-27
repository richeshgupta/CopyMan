# CopyMan - Quick Start Guide

## ✅ What's Been Built - UPDATED WITH MACCY UI!

CopyMan has been transformed with a Maccy-inspired UI and new power features!

### 🆕 NEW Features (Maccy UI Update)
- ✨ **Dark Mode** - Auto system detection + manual toggle
- ✨ **Pin/Unpin Items** - Alt+P to pin favorites to top
- ✨ **Delete Items** - Alt+Delete to remove individual entries
- ✨ **Direct Paste** - Alt+Enter to paste without switching apps
- ✨ **Tooltips** - Hover to see full content
- ✨ **Maccy Aesthetic** - Clean, minimal design

### ✅ Original Features
- ✅ **Unlimited clipboard history** with SQLite + FTS5
- ✅ **Fast hybrid search** (Trie + FTS5)
- ✅ **Global hotkeys** (Ctrl+Shift+V, Ctrl+Shift+X)
- ✅ **Background monitoring** (500ms clipboard polling)
- ✅ **Virtual scrolling** (handle 10,000+ items)
- ✅ **Keyboard navigation** (arrows + vim hjkl)
- ✅ **Real-time UI updates**
- ✅ **Cross-platform support** (Linux, macOS, Windows)

### Tech Stack
- **Backend:** Rust + Tauri 2.0
- **Frontend:** Svelte + TypeScript + Tailwind CSS
- **Database:** SQLite with FTS5 full-text search
- **Search:** radix_trie + lru cache

---

## 🚀 How to Run CopyMan

### ⚠️ IMPORTANT: GPU/Graphics Fix

You're in a headless environment. Use one of these scripts:

**Option A: Software Rendering (Fastest)**
```bash
./run-dev.sh
```

**Option B: Virtual Display**
```bash
sudo apt install xvfb  # First time only
./run-with-xvfb.sh
```

**Option C: Just Build (No Dev Server)**
```bash
npm run tauri build
# Binary: src-tauri/target/release/copyman
```

### Option 1: Development Mode (With Display Server)

```bash
cd /home/richesh/Desktop/expts/CopyMan

# Ensure Rust is in PATH
export PATH="/home/richesh/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin:$PATH"

# Run the app
./run-dev.sh  # ← Use this instead of npm run tauri dev
```

The app will:
1. Start the Vite dev server (port 5173)
2. Compile the Rust backend
3. Open a window with CopyMan
4. Start background clipboard monitoring

**Note:** The window starts hidden. Press **Ctrl+Shift+V** to show it!

### Option 2: Production Build

```bash
cd /home/richesh/Desktop/expts/CopyMan

# Build for production
npm run tauri build

# Install the generated package
sudo dpkg -i src-tauri/target/release/bundle/deb/copyman_0.1.0_amd64.deb
```

Then run from your application launcher or:
```bash
copyman
```

---

## 🎯 Testing the App

### Basic Workflow

1. **Start the app:**
   ```bash
   npm run tauri dev
   ```

2. **Copy some text** from another application (browser, terminal, etc.)
   - The text will be automatically captured to the database

3. **Press Ctrl+Shift+V** to show the CopyMan window
   - You should see your copied text in the list

4. **Search your clipboard history:**
   - Type in the search box at the top
   - Results update in real-time (300ms debounce)

5. **Navigate with keyboard:**
   - Use ↑/↓ arrow keys OR j/k (vim-style)
   - Press Enter to copy the selected item back to clipboard

6. **Try virtual scrolling:**
   - Copy many items (or use dev tools to generate test data)
   - Scroll through 10,000+ items smoothly

7. **Clear history:**
   - Press Ctrl+Shift+X
   - Confirm the dialog

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+V` | Show/hide CopyMan window |
| `Ctrl+Shift+X` | Clear all history (with confirmation) |
| `1-9, 0` | Quick select items (1=first, 0=10th) |
| `↑` / `↓` | Navigate list |
| `j` / `k` | Navigate list (vim-style) |
| `Enter` | Copy selected item to clipboard |
| **`Alt+Enter`** | **Paste directly (NEW)** ⭐ |
| **`Alt+P`** | **Pin/unpin item (NEW)** ⭐ |
| **`Delete`** | **Delete item (NEW)** ⭐ |
| `Esc` | Clear search box |

---

## 📊 Performance Verification

### Check Performance Targets

CopyMan is designed to be lightweight and fast:

**Startup Time:** Should be < 50ms
```bash
time npm run tauri dev
```

**Memory Usage:** Should be < 30MB
```bash
# While app is running
ps aux | grep copyman | awk '{print $6/1024 " MB"}'
```

**Search Performance:** Should be < 20ms
- Open browser DevTools (F12)
- Type in search box
- Check Network tab for response times

**Virtual Scrolling:** Should be 60 FPS
- Generate 10,000+ entries
- Scroll rapidly
- Check Performance tab in DevTools

---

## 🐛 Troubleshooting

### App Window Doesn't Appear

**Solution 1:** The window starts hidden - press `Ctrl+Shift+V`

**Solution 2:** Check if the process is running:
```bash
ps aux | grep copyman
```

**Solution 3:** Check logs:
```bash
# In the terminal where you ran npm run tauri dev
# Look for errors in the output
```

### Global Hotkeys Not Working

- **Cause:** Hotkeys require X11. On Wayland, they may not work depending on your compositor.
- **Solution:** Test on X11 session or check Wayland compatibility

### Compilation Errors

All compilation errors have been fixed! But if you encounter any:

```bash
# Update dependencies
cd src-tauri
cargo update

# Clean build
cargo clean
cargo build
```

### Database Location & Migration

The clipboard database is stored at:
```
~/.local/share/com.copyman.app/clipboard.db
```

**Automatic Migration:** Database migrates from v1 → v2 on first run
- Adds `is_pinned` and `pin_order` columns
- Preserves existing clipboard history
- No manual steps needed

To reset/delete:
```bash
./reset-database.sh  # Safe: creates backup first
# OR manually:
rm -rf ~/.local/share/com.copyman.app/
```

---

## 📝 What Was Fixed

### Recent Fixes (Maccy UI Update)

1. ✅ **Database Migration Error:** `no such column: is_pinned`
   - **Cause:** INIT_SQL tried to create index before columns existed
   - **Fix:** Moved column creation to migration system
   - **Details:** See `MIGRATION_FIX.md`

2. ✅ **GPU/Graphics Error:** `Could not create GBM EGL display`
   - **Cause:** Headless environment (no display server)
   - **Fix:** Created scripts with software rendering and Xvfb
   - **Details:** See `GPU_FIX_GUIDE.md`

3. ✅ **WebKit Warning:** `WEBKIT_FORCE_SANDBOX deprecated`
   - **Fix:** Updated to recommended environment variables

### Previous Fixes (Original Build)

1. ✅ **Missing trait imports:**
   - Added `GlobalShortcutExt` for hotkey registration
   - Added `Emitter` for event emission
   - Added `TrieCommon` for trie iteration
   - Added `OptionalExtension` for optional SQLite queries

2. ✅ **Borrow checker issues:**
   - Fixed lifetime issues in `search_clipboard` command
   - Properly structured mutex locks

3. ✅ **Configuration errors:**
   - Removed duplicate `identifier` field from `tauri.conf.json`

4. ✅ **Documentation:**
   - Added comprehensive Linux build instructions
   - Added system dependencies for multiple distros
   - Added troubleshooting guide

---

## 🎉 Next Steps

1. **Test the app** using the instructions above
2. **Try all features** to ensure everything works
3. **Report any issues** you find
4. **Build for production** when ready
5. **Customize** as needed (colors, shortcuts, etc.)

---

## 📚 Additional Resources

### Main Documentation
- **Implementation Summary:** `IMPLEMENTATION_SUMMARY.md` - Full changelog
- **README:** `README.md` - Project overview

### Troubleshooting Guides (NEW)
- **Migration Fix:** `MIGRATION_FIX.md` - Database migration details
- **GPU Fix:** `GPU_FIX_GUIDE.md` - Graphics error solutions
- **Quick Start:** `QUICK_START.md` - This file

### Original Documentation
- **Implementation Plan:** `docs/plans/2026-01-26-clipboard-manager.md`
- **Performance Tests:** `docs/performance-tests.md`

### Helper Scripts (NEW)
- `run-dev.sh` - Dev mode with GPU workarounds
- `run-with-xvfb.sh` - Virtual display for headless
- `reset-database.sh` - Safe database reset

---

**Enjoy using CopyMan! 🎊**
