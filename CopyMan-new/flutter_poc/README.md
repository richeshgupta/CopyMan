# CopyMan — Cross-Platform Clipboard Manager

A lightweight, fast, and feature-rich clipboard manager for Linux, Windows, and macOS. Built with Flutter for a native desktop experience.

---

## Overview

CopyMan keeps your clipboard history organized and accessible. Capture every text you copy, search through your clipboard history instantly, organize items into groups, and paste multiple items in sequence—all without slowing down your system.

### Key Features

✅ **Instant Clipboard History** — Captures every copy in real-time (500ms polling)
✅ **Fuzzy Search** — Find any clipboard item with a few keystrokes
✅ **Groups / Folders** — Organize clipboard items into categories
✅ **Sequential Paste Mode** — Paste multiple items in one go (Ctrl+V repeatedly)
✅ **Pin Important Items** — Keep frequently-used snippets at the top
✅ **App Exclusions** — Skip password managers and sensitive apps
✅ **Plain Text Paste** — Paste without formatting (Ctrl+Shift+Enter)
✅ **System Tray Icon** — Quick access from your system tray
✅ **Global Hotkey** — Show/hide with Ctrl+Alt+V
✅ **Dark & Light Themes** — Follows your system preference

---

## Quick Start

### Prerequisites

- **Flutter 3.38.9+** with Dart 3.10.8+
- **Linux:** GTK 3.0+, libsqlite3-dev, xdotool, xprop
- **macOS:** Xcode command-line tools
- **Windows:** Visual Studio Build Tools or MinGW

### Installation

```bash
cd flutter_poc
flutter pub get
flutter build linux --release
```

The binary will be at: `build/linux/x64/release/bundle/copyman`

### Running

```bash
./build/linux/x64/release/bundle/copyman
```

Or from source (debug mode):
```bash
flutter run -d linux
```

---

## Usage

### Main Interface

- **Clipboard List** — Shows your history. Click to copy.
- **Search** — Type to fuzzy-search. Matched characters are highlighted.
- **Groups Sidebar** — Organize items into groups. Click a group to filter.
- **Preview Pane** — Shows full content of selected item.

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **Ctrl+Alt+V** | Show/hide CopyMan |
| **↑ / ↓** | Navigate items |
| **Enter** | Copy selected item |
| **Ctrl+Enter** | Copy & paste |
| **Ctrl+Shift+Enter** | Paste as plain text |
| **Ctrl+A** | Select all items (multi-select mode) |
| **Ctrl+Shift+S** | Start sequence with selected items |
| **Ctrl+V** *(in sequence)* | Advance to next item & paste |
| **Escape** | Close popup / Cancel sequence |
| **Right-click** | Context menu (pin, move to group, delete, etc.) |
| **Long-press** *(on item)* | Toggle multi-select |

### Features in Detail

#### 1. **Clipboard History**

CopyMan monitors your clipboard in the background. Every time you copy something:
- It's captured automatically
- Stored in a local SQLite database
- Appears in the list immediately

You can see the last 500 items by default. The oldest unpinned items are automatically removed to keep the database lean.

#### 2. **Fuzzy Search**

Start typing to search. The search is character-based and case-insensitive. Matched characters are **bold** and highlighted.

Example:
- Query: `npmtw` → Finds: `npm install tailwind`
- Query: `gclone` → Finds: `git clone https://...`

#### 3. **Groups / Folders**

Organize your clipboard into logical groups:
- **New Group** — Click the `+` icon in the sidebar
- **Rename Group** — Right-click → Rename
- **Delete Group** — Right-click → Delete (items move to Uncategorized)
- **Move Item** — Right-click item → Move to Group
- **Filter** — Click a group to see only items in that group

The default **Uncategorized** group cannot be deleted.

#### 4. **Sequential Paste Mode**

Paste multiple items without switching windows:
1. Select multiple items (Ctrl+Click, Ctrl+A, or long-press)
2. Click "Start Sequence" or press **Ctrl+Shift+S**
3. See "Sequence Mode: Item 1/5" indicator
4. Press **Ctrl+V** to paste item 1 and move to item 2
5. Repeat until all items are pasted
6. Press **Escape** to cancel anytime

Perfect for pasting multiple lines of code, configuration values, or bulk data entry.

#### 5. **Pin Important Items**

Right-click an item → **Pin** to keep it at the top, even as you copy new things. Pinned items are never auto-removed.

#### 6. **App Exclusions**

Skip capturing clipboard from sensitive apps (password managers, etc.). Pre-configured exclusions:
- 1Password
- Bitwarden
- LastPass
- KeePass / KeePassXC
- Enpass
- Dashlane
- Keeper

Text copied from these apps won't appear in history.

#### 7. **Paste as Plain Text**

Right-click an item → **Paste as Plain** or press **Ctrl+Shift+Enter** to paste without formatting. Useful when pasting into rich-text editors.

---

## Architecture

### Tech Stack

- **UI Framework:** Flutter (Material Design 3)
- **Database:** SQLite 3 (with sqflite_ffi)
- **Clipboard Access:** xclip (Linux), native APIs (macOS/Windows)
- **Hotkey Binding:** hotkey_manager + HardwareKeyboard
- **Window Management:** window_manager
- **System Tray:** tray_manager

### Project Structure

```
flutter_poc/
├── lib/
│   ├── main.dart                        # App entry point
│   ├── app.dart                         # MaterialApp config
│   ├── theme/
│   │   └── app_theme.dart               # Light/dark themes
│   ├── models/
│   │   ├── clipboard_item.dart          # Data model for clipboard items
│   │   ├── group.dart                   # Data model for groups
│   │   └── sequence_session.dart        # Session state for sequential paste
│   ├── services/
│   │   ├── storage_service.dart         # SQLite CRUD & schema
│   │   ├── clipboard_service.dart       # Clipboard polling (500ms)
│   │   ├── hotkey_service.dart          # Global hotkey registration
│   │   ├── tray_service.dart            # System tray icon
│   │   ├── group_service.dart           # Group management
│   │   ├── sequence_service.dart        # Sequential paste state
│   │   ├── app_detection_service.dart   # Detect foreground app (Linux)
│   │   └── fuzzy_search.dart            # In-memory fuzzy search
│   ├── screens/
│   │   └── home_screen.dart             # Main popup UI
│   └── widgets/
│       ├── clipboard_item_tile.dart     # Item list row
│       └── groups_panel.dart            # Groups sidebar
├── linux/                               # Linux build config (CMake, GTK)
├── windows/                             # Windows build config (CMake)
├── macos/                               # macOS build config (Xcode)
├── assets/
│   └── icons/
│       └── tray_icon.png                # System tray icon
├── pubspec.yaml                         # Flutter dependencies
└── README.md                            # This file
```

### Database Schema (v3)

```sql
CREATE TABLE clipboard_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  content TEXT NOT NULL,
  content_type TEXT DEFAULT 'text',
  content_hash TEXT,
  content_bytes BLOB,
  pinned INTEGER DEFAULT 0,
  group_id INTEGER DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY(group_id) REFERENCES groups(id)
);

CREATE TABLE groups (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT UNIQUE NOT NULL,
  color TEXT DEFAULT '#4CAF50',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE app_exclusions (
  app_name TEXT PRIMARY KEY,
  blocked INTEGER DEFAULT 1
);

CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE INDEX idx_group_id ON clipboard_items(group_id);
```

### Services Overview

| Service | Purpose |
|---------|---------|
| **StorageService** | SQLite CRUD, schema management, database migrations |
| **ClipboardService** | Real-time clipboard monitoring (500ms poll) |
| **HotKeyService** | Register/unregister global hotkeys |
| **TrayService** | System tray icon and context menu |
| **GroupService** | Full group management (CRUD, move items, counts) |
| **SequenceService** | Session state for sequential paste mode |
| **AppDetectionService** | Detect foreground app for exclusion checking |
| **FuzzySearch** | In-memory fuzzy search with scoring and highlighting |

---

## Development

### Building from Source

#### Linux

```bash
export PATH="$HOME/bin:$PATH"  # Use custom clang++ wrapper (see notes below)
cd flutter_poc
flutter pub get
flutter build linux --release
```

**Linker Workaround on Linux:**

If you get linker errors about missing `ld`, create a wrapper script:

```bash
mkdir -p ~/bin
cat > ~/bin/clang++ << 'EOF'
#!/bin/bash
/usr/lib/llvm-18/bin/clang++ "$@"
EOF
chmod +x ~/bin/clang++
ln -s /usr/bin/ld ~/bin/ld
export PATH=$HOME/bin:$PATH
```

#### macOS

```bash
cd flutter_poc
flutter pub get
flutter build macos --release
```

#### Windows

```bash
cd flutter_poc
flutter pub get
flutter build windows --release
```

### Running Tests

```bash
flutter analyze lib/             # Lint checks
flutter test                     # Unit tests (not yet implemented)
```

### Adding New Features

1. **Database Schema Changes:** Update `storage_service.dart` migration handler, bump version
2. **New Services:** Add to `lib/services/`
3. **New Models:** Add to `lib/models/`
4. **UI Changes:** Update screens or widgets in `lib/screens/` and `lib/widgets/`

Always run `flutter analyze` and `flutter build linux --release` before committing.

---

## Roadmap

### Phase 1 ✅ (Delivered)

- [x] Clipboard history capture & display
- [x] Fuzzy search with highlighting
- [x] Pin/unpin items
- [x] App exclusion list
- [x] Configurable history size (data layer)
- [x] System tray icon
- [x] Global hotkey (Ctrl+Alt+V)
- [x] Paste as plain text
- [x] Dark/light themes

### Phase 2 ✅ (Delivered)

- [x] Groups / Folders for organization
- [x] Sequential Paste Mode
- [x] Multi-select with Ctrl+Click, Ctrl+A, long-press
- [x] Group filtering
- [x] Move items to groups
- [x] Item counts per group
- [x] Responsive sidebar

### Phase 2.1 (Planned)

- [ ] Group color coding in sidebar
- [ ] Settings screen with history size slider
- [ ] App exclusion list editor (UI)
- [ ] TTL-based auto-clear for old items

### Phase 3 (Planned)

- [ ] LAN peer discovery (mDNS)
- [ ] P2P sync protocol
- [ ] Zero-knowledge relay server
- [ ] End-to-end encryption (E2EE)
- [ ] Device pairing UI

### Post-1.0 (Future)

- [ ] Image capture & thumbnail rendering
- [ ] Mobile companion apps (iOS/Android)
- [ ] Managed relay hosting
- [ ] Scripting / macro engine
- [ ] Vim keybindings mode

---

## Performance

- **Startup Time:** <500ms (debug), <100ms (release)
- **Clipboard Polling:** 500ms intervals, <1% CPU idle
- **Fuzzy Search:** <50ms for 500–10k items (in-memory)
- **Memory Footprint:** 30–50 MB (debug), 15–25 MB (release)
- **Database:** SQLite with indexes, < 1MB for 500 items (text-only)

---

## Troubleshooting

### App doesn't capture clipboard (Linux)

**Issue:** `xdotool`, `xprop`, or `xclip` not installed.

**Fix:**
```bash
sudo apt install xdotool x11-utils xclip  # Ubuntu/Debian
sudo dnf install xdotool xprop xclip      # Fedora
```

### Hotkey (Ctrl+Alt+V) doesn't work

**Issue:** Another app has bound the same hotkey, or the X11 display is not available (Wayland).

**Fix:**
1. Check if another app uses Ctrl+Alt+V (e.g., GNOME Settings)
2. Rebind in settings (planned for Phase 2.1)
3. On Wayland, use the system app launcher instead of hotkey

### Database is locked

**Issue:** Another CopyMan instance is running, or the database file is corrupted.

**Fix:**
```bash
# Kill all CopyMan instances
pkill copyman

# Remove and recreate the database (last 500 items will be lost)
rm ~/.local/share/copyman/copyman.db
```

### High memory usage

**Issue:** Too many items in history (>10k).

**Fix:**
1. Open CopyMan
2. Delete old items or reduce history limit (Phase 2.1)
3. Clear database: `rm ~/.local/share/copyman/copyman.db`

---

## Contributing

CopyMan is open source and welcomes contributions.

- **Bug Reports:** [GitHub Issues](https://github.com/richeshgupta/CopyMan/issues)
- **Feature Requests:** [GitHub Discussions](https://github.com/richeshgupta/CopyMan/discussions)
- **Code Contributions:** Fork → Feature Branch → Pull Request

### Code Style

- Follow Flutter conventions (https://dart.dev/guides/language/effective-dart)
- Run `dart format lib/` before committing
- No `// ignore: ` comments unless unavoidable

---

## License

MIT License — See LICENSE file for details.

---

## Credits

Built by [Richesh Gupta](https://github.com/richeshgupta)

- **Design Inspiration:** Maccy (macOS), CopyQ (Linux), Ditto (Windows)
- **Flutter Community:** For excellent documentation and plugins
- **SQLite:** For rock-solid reliability

---

## Support

- **Documentation:** [GitHub Wiki](https://github.com/richeshgupta/CopyMan/wiki)
- **Issues & Feedback:** [GitHub Issues](https://github.com/richeshgupta/CopyMan/issues)
- **Email:** [GitHub Profile](https://github.com/richeshgupta)

---

**CopyMan — Copy smarter. Paste faster.**
