# CopyMan — Features & Architecture

A lightweight, fast, and feature-rich clipboard manager for Linux, Windows, and macOS. Built with Flutter for a native desktop experience.

**Status:** ✅ Phase 2 Complete | **License:** MIT | **Built with:** Flutter 3.38.9

**Platform Support:**
- ✅ **Linux:** Fully functional (xclip, xdotool, xprop) — Production-ready
- ⚠️ **macOS:** Image capture via osascript implemented — Needs comprehensive testing
- 🔄 **Windows:** Code structure ready — Requires platform validation

---

## 🎯 What is CopyMan?

CopyMan is a smart clipboard manager that captures every text you copy, lets you search through your history instantly, organize items into groups, and even paste multiple items in sequence—all without slowing down your system.

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **📋 Clipboard History** | Real-time capture (500ms polling) • Text & images • Auto-cleanup • SQLite storage |
| **🔍 Fuzzy Search** | Instant search • Case-insensitive • Character highlighting |
| **📁 Groups / Folders** | Organize items • Create/rename/delete groups • Filter by group |
| **🔄 Sequential Paste** | Multi-select items • Paste multiple items in sequence (Ctrl+V) |
| **📌 Pin Items** | Keep important snippets at top • Survive auto-cleanup |
| **🚫 App Exclusions** | Skip password managers & sensitive apps • Sensitive content detection |
| **📄 Plain Text Paste** | Paste without formatting • Remove styles & links |
| **🎨 Dark & Light Themes** | Automatic theme switching based on system preference |
| **🪟 System Tray** | Quick access from system tray • Minimize to tray |
| **⌨️ Global Hotkey** | Show/hide with Ctrl+Alt+V • Always accessible |
| **⚙️ Configurable Shortcuts** | Customize all keyboard shortcuts • Conflict detection • Help overlay (Shift+/) |
| **🖼️ Image Clipboard** | Capture images from clipboard • File path detection • Size limits • Hash-based deduplication |
| **📦 Distribution** | Snap package • .deb package • Portable binary |

## 🚀 Quick Start

### Prerequisites

- **Flutter 3.38.9+** with Dart 3.10.8+
- **Linux:** GTK 3.0+, libsqlite3-dev, xdotool, xprop, xclip
- **macOS:** Xcode command-line tools, osascript (for image capture)
- **Windows:** Visual Studio Build Tools or MinGW (code ready, needs testing)

### Installation

```bash
cd copyman
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
| **Ctrl+P** | Pin/unpin selected item |
| **Delete** | Delete selected item |
| **Ctrl+,** | Open settings |
| **Space** | Preview selected item (overlay) |

*All shortcuts are customizable in Settings → Shortcuts*

## 📊 Feature Roadmap

| Phase | Status | Features |
|-------|--------|----------|
| **Phase 1** | ✅ Complete | Clipboard history, fuzzy search, pinning, app exclusions, system tray, hotkey, themes, image capture |
| **Phase 2** | ✅ Complete | Groups/folders, sequential paste, multi-select, configurable shortcuts, sensitive detection, Snap/.deb packaging |
| **Phase 3** | ⚠️ Testing | macOS clipboard APIs implemented (osascript for images), comprehensive testing needed |
| **Phase 4** | 🔄 Testing | Windows app detection and clipboard code ready, requires platform validation |
| **Phase 5** | 📋 Future | LAN P2P sync, zero-knowledge relay, E2EE, device pairing, mobile apps |

## 📁 Project Structure

```
.
├── copyman/                        (Flutter application)
│   ├── lib/
│   │   ├── models/                 (Data models: ClipboardItem, Group, SequenceSession)
│   │   ├── services/               (Business logic: Storage, Clipboard, Hotkey, etc.)
│   │   ├── screens/                (UI screens: HomeScreen, SettingsScreen)
│   │   ├── widgets/                (UI components: ItemTile, GroupsPanel, etc.)
│   │   ├── theme/                  (Light/dark themes)
│   │   ├── main.dart               (Entry point)
│   │   └── app.dart                (MaterialApp config)
│   ├── pubspec.yaml                (Dependencies & metadata)
│   ├── linux/                      (Linux platform config)
│   ├── windows/                    (Windows platform config)
│   ├── macos/                      (macOS platform config)
│   └── build/                      (Build artifacts)
├── docs/                           (Documentation & guides)
├── .github/                        (GitHub config & CI/CD workflows)
├── FEATURES_AND_ARCHITECTURE.md    (This file)
├── DEVELOPMENT.md                  (Development guide)
├── CONTRIBUTING.md                 (Contribution guidelines)
└── LICENSE                         (MIT License)
```

## 🏗️ Architecture

### Tech Stack

- **UI:** Flutter (Material Design 3) + Dart
- **Database:** SQLite 3 (sqflite_common_ffi)
- **Clipboard:** xclip (Linux), osascript (macOS), Flutter Clipboard API (cross-platform text)
- **Hotkey:** hotkey_manager + HardwareKeyboard
- **Window:** window_manager
- **Tray:** tray_manager
- **Search:** Custom fuzzy search implementation

### Core Services

| Service | Purpose | File |
|---------|---------|------|
| **StorageService** | SQLite CRUD, schema management, database migrations | `services/storage_service.dart` |
| **ClipboardService** | Real-time clipboard monitoring (500ms polling) | `services/clipboard_service.dart` |
| **HotKeyService** | Global hotkey registration & management | `services/hotkey_service.dart` |
| **HotKeyConfigService** | Persistent hotkey configuration & customization | `services/hotkey_config_service.dart` |
| **TrayService** | System tray icon & context menu | `services/tray_service.dart` |
| **GroupService** | Group CRUD operations, item management | `services/group_service.dart` |
| **SequenceService** | Sequential paste session management | `services/sequence_service.dart` |
| **AppDetectionService** | Detect foreground app (for exclusions) | `services/app_detection_service.dart` |
| **FuzzySearch** | In-memory fuzzy search with scoring | `services/fuzzy_search.dart` |

### Data Models

- **ClipboardItem** — Individual clipboard entry (text/image) with timestamp, hash, content bytes, groups
- **Group** — Organization folder with name, color, metadata
- **SequenceSession** — State for sequential paste mode (active items, index)
- **HotkeyBinding** — Keyboard shortcut configuration (modifiers + key)
- **AppAction** — Enum of 13 customizable actions

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
cd copyman
flutter build linux --release
```

#### macOS (coming soon)
```bash
cd copyman
flutter build macos --release
```

#### Windows (coming soon)
```bash
cd copyman
flutter build windows --release
```

### Linting & Testing

```bash
cd copyman
flutter analyze lib/              # Code quality check
flutter test                      # Unit tests
```

### GitHub Actions CI/CD

Automated checks run on every PR and push:
- ✅ **flutter-analyze.yml** — Code quality checks
- ✅ **flutter-test.yml** — Unit tests with coverage
- ✅ **flutter-build.yml** — Build verification (Linux + Web)

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| **Clipboard not capturing (Linux)** | Install: `sudo apt install xdotool x11-utils xclip` |
| **Hotkey not working** | Check if another app uses Ctrl+Alt+V, customize in Settings, or restart |
| **Database locked** | Kill process: `pkill copyman` and remove DB: `rm ~/.local/share/copyman/copyman.db` |
| **High memory usage** | Clear old items in settings or reduce history retention limit |
| **Build fails on Linux** | Ensure GTK dev packages installed: `sudo apt install libgtk-3-dev` |

## 🤝 Contributing

We welcome contributions! Here's how:

1. **Report bugs:** [GitHub Issues](https://github.com/richeshgupta/CopyMan/issues)
2. **Suggest features:** [GitHub Discussions](https://github.com/richeshgupta/CopyMan/discussions)
3. **Submit code:** Fork → Feature Branch → Pull Request

See [CONTRIBUTING](./CONTRIBUTING.md) for detailed guidelines.

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Run `dart format lib/` before committing
- Keep files small and focused

## 📜 License

MIT License — See [LICENSE](./LICENSE) file for details.

## 👤 Credits

**Built by:** [Richesh Gupta](https://github.com/richeshgupta)

**Design Inspiration:** Maccy (macOS), CopyQ (Linux), Ditto (Windows)

**Community:** Thanks to Flutter community & open-source contributors

## 🔗 Links

- **Repository:** https://github.com/richeshgupta/CopyMan
- **Issues:** https://github.com/richeshgupta/CopyMan/issues
- **Discussions:** https://github.com/richeshgupta/CopyMan/discussions
- **Development Guide:** [DEVELOPMENT.md](./docs/DEVELOPMENT.md)

---

**CopyMan — Copy smarter. Paste faster.** ⚡
