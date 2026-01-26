# CopyMan - Quick Start Guide

## ✅ What's Been Built

CopyMan is now fully implemented and ready to test! Here's what you have:

### Features Implemented
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

### Option 1: Development Mode (Recommended for Testing)

```bash
cd /home/richesh/Desktop/expts/CopyMan

# Ensure Rust is in PATH
export PATH="/home/richesh/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin:$PATH"

# Run the app
npm run tauri dev
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
| `↑` / `↓` | Navigate list |
| `j` / `k` | Navigate list (vim-style) |
| `Enter` | Copy selected item to clipboard |
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

### Database Location

The clipboard database is stored at:
```
~/.local/share/com.copyman.app/clipboard.db
```

To reset/delete:
```bash
rm -rf ~/.local/share/com.copyman.app/
```

---

## 📝 What Was Fixed

During the build process, these issues were resolved:

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

- **Implementation Plan:** `docs/plans/2026-01-26-clipboard-manager.md`
- **Implementation Summary:** `IMPLEMENTATION_SUMMARY.md`
- **Performance Tests:** `docs/performance-tests.md`
- **README:** `README.md`

---

**Enjoy using CopyMan! 🎊**
