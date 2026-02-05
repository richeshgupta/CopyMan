# CopyMan — Cross-Platform Clipboard Manager

A lightweight, fast, and feature-rich clipboard manager for Linux, Windows, and macOS. Built with Flutter for a native desktop experience.

**Status:** ✅ Phase 2 Complete | **License:** MIT | **Built with:** Flutter 3.38.9

---

## 🎯 What is CopyMan?

CopyMan is a smart clipboard manager that captures every text you copy, lets you search through your history instantly, organize items into groups, and even paste multiple items in sequence—all without slowing down your system.

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **📋 Clipboard History** | Real-time capture (500ms polling) • Auto-cleanup • SQLite storage |
| **🔍 Fuzzy Search** | Instant search • Case-insensitive • Character highlighting |
| **📁 Groups / Folders** | Organize items • Create/rename/delete groups • Filter by group |
| **🔄 Sequential Paste** | Multi-select items • Paste multiple items in sequence (Ctrl+V) |
| **📌 Pin Items** | Keep important snippets at top • Survive auto-cleanup |
| **🚫 App Exclusions** | Skip password managers & sensitive apps automatically |
| **📄 Plain Text Paste** | Paste without formatting • Remove styles & links |
| **🎨 Dark & Light Themes** | Automatic theme switching based on system preference |
| **🪟 System Tray** | Quick access from system tray • Minimize to tray |
| **⌨️ Global Hotkey** | Show/hide with Ctrl+Alt+V • Always accessible |

## 🚀 Quick Start

### Prerequisites

- **Flutter 3.38.9+** with Dart 3.10.8+
- **Linux:** GTK 3.0+, libsqlite3-dev, xdotool, xprop
- **macOS:** Xcode command-line tools
- **Windows:** Visual Studio Build Tools or MinGW

### Installation

```bash
cd CopyMan/copyman
flutter pub get
flutter build linux --release
```

**Binary location:** `build/linux/x64/release/bundle/copyman`

### Running

```bash
./build/linux/x64/release/bundle/copyman
```

Or from source (debug mode):
```bash
flutter run -d linux
```

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **Ctrl+Alt+V** | Show/hide CopyMan |
| **↑ / ↓** | Navigate items |
| **Enter** | Copy selected item |
| **Ctrl+Enter** | Copy & paste |
| **Ctrl+Shift+Enter** | Paste as plain text |
| **Ctrl+A** | Select all items (multi-select) |
| **Ctrl+Shift+S** | Start sequence with selected items |
| **Ctrl+V** *(in sequence)* | Advance to next item & paste |
| **Escape** | Close popup / Cancel sequence |
| **Right-click** | Context menu (pin, move to group, delete) |
| **Long-press** | Toggle multi-select on item |

## 📊 Roadmap

| Phase | Status | Features |
|-------|--------|----------|
| **Phase 1** | ✅ Complete | Clipboard history, fuzzy search, pinning, app exclusions, system tray, hotkey, themes |
| **Phase 2** | ✅ Complete | Groups/folders, sequential paste mode, multi-select, responsive UI |
| **Phase 2.1** | 📋 Planned | Group colors, settings screen, app exclusion editor, auto-cleanup |
| **Phase 3** | 📋 Planned | LAN P2P sync, zero-knowledge relay, E2EE, device pairing |
| **Post-1.0** | 📋 Future | Image capture, mobile apps, managed relay, scripting engine |

## 📁 Project Structure

```
CopyMan/
├── copyman/                        (Flutter application)
│   ├── lib/
│   │   ├── models/                 (Data models: ClipboardItem, Group, SequenceSession)
│   │   ├── services/               (Business logic: Storage, Clipboard, Hotkey, etc.)
│   │   ├── screens/                (UI screens: HomeScreen)
│   │   ├── widgets/                (UI components: ItemTile, GroupsPanel)
│   │   ├── theme/                  (Light/dark themes)
│   │   ├── main.dart               (Entry point)
│   │   └── app.dart                (MaterialApp config)
│   ├── pubspec.yaml                (Dependencies & metadata)
│   ├── README.md                   (Detailed documentation)
│   ├── linux/                      (Linux platform config)
│   ├── windows/                    (Windows platform config)
│   ├── macos/                      (macOS platform config)
│   └── build/                      (Build artifacts)
├── docs/                           (Documentation & guides)
├── PHASE-1-COMPLETION.md           (Phase 1 summary)
├── PHASE-2-COMPLETION.md           (Phase 2 summary)
└── RENAME-VERIFICATION.md          (Rename details)
```

## 🏗️ Architecture

### Tech Stack

- **UI:** Flutter (Material Design 3)
- **Database:** SQLite 3 (sqflite_ffi)
- **Clipboard:** xclip (Linux), native APIs (macOS/Windows)
- **Hotkey:** hotkey_manager + HardwareKeyboard
- **Window:** window_manager
- **Tray:** tray_manager

### Services

| Service | Purpose |
|---------|---------|
| **StorageService** | SQLite CRUD, schema management, database migrations |
| **ClipboardService** | Real-time clipboard monitoring (500ms polling) |
| **HotKeyService** | Global hotkey registration & management |
| **TrayService** | System tray icon & context menu |
| **GroupService** | Group CRUD operations, item management |
| **SequenceService** | Sequential paste session management |
| **AppDetectionService** | Detect foreground app (for exclusions) |
| **FuzzySearch** | In-memory fuzzy search with scoring |

## 📊 Performance

- **Startup:** <500ms (debug), <100ms (release)
- **Polling:** 500ms intervals, <1% CPU idle
- **Search:** <50ms for 10k items (in-memory)
- **Memory:** 30-50MB (debug), 15-25MB (release)
- **Database:** <1MB for 500 items

## 🛠️ Development

### Build from Source

#### Linux
```bash
export PATH="$HOME/bin:$PATH"  # If using linker workaround
cd CopyMan/copyman
flutter build linux --release
```

#### macOS
```bash
cd CopyMan/copyman
flutter build macos --release
```

#### Windows
```bash
cd CopyMan/copyman
flutter build windows --release
```

### Linting & Testing

```bash
flutter analyze lib/              # Code quality check
flutter test                      # Unit tests
```

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Clipboard not capturing (Linux)** | Install: `sudo apt install xdotool x11-utils xclip` |
| **Hotkey not working** | Check if another app uses Ctrl+Alt+V, or use system launcher |
| **Database locked** | Kill process: `pkill copyman` and remove DB: `rm ~/.local/share/copyman/copyman.db` |
| **High memory usage** | Clear old items or reduce history limit (Phase 2.1) |

## 🤝 Contributing

We welcome contributions! Here's how:

1. **Report bugs:** [GitHub Issues](https://github.com/richeshgupta/CopyMan/issues)
2. **Suggest features:** [GitHub Discussions](https://github.com/richeshgupta/CopyMan/discussions)
3. **Submit code:** Fork → Feature Branch → Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Run `dart format lib/` before committing
- Keep files small and focused

## 📜 License

MIT License — See [LICENSE](LICENSE) file for details.

## 👤 Credits

**Built by:** [Richesh Gupta](https://github.com/richeshgupta)

**Design Inspiration:** Maccy (macOS), CopyQ (Linux), Ditto (Windows)

**Community:** Thanks to Flutter community & open-source contributors

## 🔗 Links

- **Repository:** https://github.com/richeshgupta/CopyMan
- **Issues:** https://github.com/richeshgupta/CopyMan/issues
- **Discussions:** https://github.com/richeshgupta/CopyMan/discussions
- **Detailed Docs:** [copyman/README.md](CopyMan/copyman/README.md)

---

**CopyMan — Copy smarter. Paste faster.** ⚡

For detailed documentation, see [copyman/README.md](CopyMan/copyman/README.md)
