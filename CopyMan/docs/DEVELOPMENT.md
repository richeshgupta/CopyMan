# CopyMan Development Guide

This document provides detailed information for developers working on CopyMan. It covers setup, architecture, database schema, key concepts, and common development workflows.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Database Schema](#database-schema)
- [Key Concepts](#key-concepts)
- [Development Workflows](#development-workflows)
- [Adding New Features](#adding-new-features)
- [Build Process](#build-process)
- [Testing](#testing)
- [Common Issues](#common-issues)

---

## Prerequisites

### Required Software

- **Flutter:** 3.38.9 or higher
- **Dart:** 3.10.8 or higher
- **Git:** For version control

### Platform-Specific Requirements

#### Linux
```bash
sudo apt-get install \
  libgtk-3-dev \
  libsqlite3-dev \
  xdotool \
  x11-utils \
  xclip \
  clang \
  cmake \
  ninja-build \
  pkg-config
```

#### macOS
- Xcode Command Line Tools: `xcode-select --install`

#### Windows
- Visual Studio 2022 with "Desktop development with C++" workload
- OR MinGW-w64

---

## Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/richeshgupta/CopyMan.git
cd CopyMan/copyman
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Verify Flutter Installation

```bash
flutter doctor -v
flutter config --enable-linux-desktop
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
```

### 4. Run in Debug Mode

```bash
flutter run -d linux
# or
flutter run -d macos
# or
flutter run -d windows
```

---

## Project Structure

```
copyman/
├── lib/
│   ├── main.dart                            # Entry point: initializes services, window config
│   ├── app.dart                             # MaterialApp widget, routing, theme
│   │
│   ├── models/                              # Data models
│   │   ├── clipboard_item.dart              # ClipboardItem model (fromMap, relativeTime)
│   │   ├── group.dart                       # Group model for organizing items
│   │   └── sequence_session.dart            # Sequential paste session state
│   │
│   ├── services/                            # Business logic layer
│   │   ├── storage_service.dart             # SQLite CRUD operations
│   │   ├── clipboard_service.dart           # Clipboard monitoring (500ms polling)
│   │   ├── hotkey_service.dart              # Global hotkey registration (Ctrl+Alt+V)
│   │   ├── hotkey_config_service.dart       # Configurable keyboard shortcuts
│   │   ├── group_service.dart               # Group management
│   │   ├── sequence_service.dart            # Sequential paste logic
│   │   ├── app_detection_service.dart       # Foreground app detection (for exclusions)
│   │   ├── fuzzy_search.dart                # In-memory fuzzy search with scoring
│   │   └── tray_service.dart                # System tray integration
│   │
│   ├── screens/                             # Full-screen UI pages
│   │   ├── home_screen.dart                 # Main popup window (search + list + preview)
│   │   └── settings_screen.dart             # Settings page (4 tabs: General, Exclusions, Shortcuts, Groups)
│   │
│   ├── widgets/                             # Reusable UI components
│   │   ├── clipboard_item_tile.dart         # Single item row (pin icon, content, time)
│   │   ├── group_filter_chips.dart          # Group filter chip row
│   │   └── groups_panel.dart                # Group management sidebar (deprecated)
│   │
│   └── theme/
│       └── app_theme.dart                   # Light/dark theme definitions
│
├── assets/
│   └── icons/
│       └── tray_icon.png                    # System tray icon
│
├── linux/                                    # Linux platform-specific config
├── macos/                                    # macOS platform-specific config
├── windows/                                  # Windows platform-specific config
├── test/                                     # Unit tests
└── pubspec.yaml                              # Dependencies and metadata
```

---

## Architecture Overview

CopyMan follows a **service-based architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────┐
│                  UI Layer (Screens)                 │
│         home_screen.dart  settings_screen.dart      │
└────────────────────┬────────────────────────────────┘
                     │ Calls services
┌────────────────────┴────────────────────────────────┐
│              Service Layer (Business Logic)         │
│  - StorageService        - ClipboardService         │
│  - HotkeyService         - HotkeyConfigService      │
│  - GroupService          - SequenceService          │
│  - FuzzySearch           - AppDetectionService      │
│  - TrayService                                      │
└────────────────────┬────────────────────────────────┘
                     │ Reads/Writes
┌────────────────────┴────────────────────────────────┐
│            Data Layer (SQLite Database)             │
│  Tables: clipboard_items, groups, settings,         │
│          app_exclusions                             │
└─────────────────────────────────────────────────────┘
```

### Design Principles

1. **Singleton Services:** All services use the singleton pattern (`Service.instance`)
2. **Immutable Models:** Data models are immutable value objects
3. **Reactive Updates:** Services emit streams/callbacks for UI updates
4. **Database-First:** SQLite is the single source of truth
5. **Platform-Agnostic:** Core logic is platform-independent; platform-specific code is isolated

---

## Database Schema

CopyMan uses SQLite (via `sqflite_common_ffi`) with the following schema (version 3):

### Tables

#### `clipboard_items`
Stores clipboard history with text content, metadata, and relationships.

```sql
CREATE TABLE clipboard_items (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  content        TEXT    NOT NULL,
  type           TEXT    NOT NULL DEFAULT 'text',
  pinned         INTEGER NOT NULL DEFAULT 0,      -- 0 = false, 1 = true
  created_at     INTEGER NOT NULL,                -- Unix timestamp (ms)
  updated_at     INTEGER NOT NULL,                -- Unix timestamp (ms)
  content_bytes  BLOB,                            -- Future: for image content
  content_hash   TEXT,                            -- Future: for deduplication
  group_id       INTEGER DEFAULT 1                -- FK to groups.id
                 REFERENCES groups(id) ON DELETE SET NULL
);

CREATE INDEX idx_order ON clipboard_items(pinned DESC, updated_at DESC);
CREATE INDEX idx_group_id ON clipboard_items(group_id);
```

#### `groups`
Stores user-defined groups for organizing clipboard items.

```sql
CREATE TABLE groups (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT UNIQUE NOT NULL,
  color      TEXT DEFAULT '#4CAF50',              -- Hex color code
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

**Default Group:** ID 1 = "Uncategorized" (gray, cannot be deleted)

#### `settings`
Key-value store for application settings.

```sql
CREATE TABLE settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

**Common Keys:**
- `history_limit` (default: 500) - Maximum number of unpinned items
- `ttl_enabled` ("true" or "false") - Enable auto-cleanup
- `ttl_hours` (default: 72) - Hours before auto-deletion
- `hotkey.<action>` - Custom keyboard shortcuts (e.g., `hotkey.toggleWindow`)

#### `app_exclusions`
List of applications to exclude from clipboard monitoring (e.g., password managers).

```sql
CREATE TABLE app_exclusions (
  app_name TEXT PRIMARY KEY,
  blocked  INTEGER NOT NULL DEFAULT 1            -- 0 = false, 1 = true
);
```

**Pre-seeded Apps:** 1Password, Bitwarden, LastPass, KeePass, KeePassXC, Enpass, Dashlane, Keeper

### Database Location

- **Linux:** `~/.local/share/copyman/copyman.db`
- **macOS:** `~/Library/Application Support/copyman/copyman.db`
- **Windows:** `%APPDATA%\copyman\copyman.db`

---

## Key Concepts

### 1. StorageService

The `StorageService` is a singleton that manages all database operations.

**Key Methods:**
```dart
// Initialize database (call once at startup)
await StorageService.instance.init();

// Insert or update (bumps updated_at if duplicate exists)
int id = await StorageService.instance.insertOrUpdate(
  "Hello World",
  type: "text",
);

// Fetch items with optional search filter
List<ClipboardItem> items = await StorageService.instance.fetchItems(
  search: "hello",
  limit: 200,
);

// Toggle pin status
await StorageService.instance.togglePin(itemId);

// Delete item
await StorageService.instance.deleteItem(itemId);

// Generic settings
String? value = await StorageService.instance.getSetting('key');
await StorageService.instance.setSetting('key', 'value');

// Exclusions
bool excluded = await StorageService.instance.isAppExcluded('1Password');
await StorageService.instance.setExclusion('MyApp', true);
```

**Housekeeping:**
- `_enforceLimit()` automatically removes oldest unpinned items beyond `history_limit`
- `clearExpiredItems()` removes items older than TTL (if enabled)

### 2. ClipboardService

Polls the system clipboard every 500ms to detect new content.

**Workflow:**
1. Poll clipboard with `Clipboard.getData('text/plain')`
2. Check if content is new (differs from `_lastContent`)
3. Check if foreground app is excluded (via `AppDetectionService`)
4. Insert into database (or bump `updated_at` if duplicate)
5. Emit `onNewItem` stream with row ID

**Usage:**
```dart
final clipboardService = ClipboardService();
clipboardService.startMonitoring();

// Listen for new items
clipboardService.onNewItem.listen((id) {
  print("New item inserted: $id");
  // Refresh UI
});

// Before programmatic paste (prevents re-capture)
clipboardService.setLastContent("content to paste");
```

### 3. FuzzySearch

Performs in-memory fuzzy matching on clipboard items.

**Algorithm:**
- Case-insensitive character-by-character matching
- All query characters must appear in order in the content
- **Scoring:**
  - +2.0 per match
  - +0.5 bonus if match is within first 10 characters
  - +1.0 per contiguous match (adjacent characters)
  - -0.1 per extra character in content vs query
- Results sorted by score descending

**Usage:**
```dart
List<FuzzyMatch> results = FuzzySearch.search("hlo", items);
// Matches: "Hello", "halo", "help out", etc.

for (final match in results) {
  print("${match.item.content} (score: ${match.score})");
  print("Match indices: ${match.matchIndices}");
}
```

### 4. SequenceService

Manages sequential paste sessions (multi-paste).

**Workflow:**
1. User selects multiple items (Ctrl+A or long-press)
2. Start sequence: `Ctrl+Shift+S`
3. Each `Ctrl+V` pastes the next item in sequence
4. Progress shown in status bar: "Sequence: 2/5"
5. Auto-cancels when sequence completes or user presses `Escape`

**Usage:**
```dart
final sequenceService = SequenceService();

// Start sequence
sequenceService.startSequence([item1, item2, item3]);

// In paste handler
if (sequenceService.isActive) {
  final item = sequenceService.getCurrentItem();
  // Paste item.content
  sequenceService.advance();
}

// Check progress
String progress = sequenceService.progress; // "1/3"
bool done = sequenceService.isComplete;
```

### 5. HotkeyConfigService

Provides configurable keyboard shortcuts for all app actions.

**Actions:** (13 total)
- `toggleWindow`, `copy`, `copyAndPaste`, `pastePlain`
- `deleteItem`, `togglePin`, `selectAll`, `startSequence`
- `togglePreview`, `moveUp`, `moveDown`, `close`, `openSettings`

**Usage:**
```dart
await HotkeyConfigService.instance.init();

// Check if event matches action
if (HotkeyConfigService.instance.matches(AppAction.togglePin, event)) {
  // Handle pin toggle
}

// Get binding description
String desc = HotkeyConfigService.instance.describeBinding(AppAction.copy);
// "Enter"

// Set custom binding
await HotkeyConfigService.instance.setBinding(
  AppAction.copy,
  HotkeyBinding(key: LogicalKeyboardKey.keyC, ctrl: true),
);

// Check for conflicts
AppAction? conflict = HotkeyConfigService.instance.findConflict(
  AppAction.copy,
  newBinding,
);

// Reset all to defaults
await HotkeyConfigService.instance.resetAllToDefaults();
```

**Storage:** Bindings are persisted in `settings` table as `hotkey.<action>` keys.

### 6. AppDetectionService

Detects the foreground application to enable app-based exclusions.

**Platform-Specific:**
- **Linux:** Uses `xdotool getactivewindow getwindowname` and `xprop`
- **macOS:** Uses AppleScript or native APIs
- **Windows:** Uses Win32 API

**Usage:**
```dart
String? appName = await AppDetectionService.getForegroundApp();
// Returns: "1Password", "Firefox", "Code", null (if detection fails)
```

---

## Development Workflows

### Hot Reload

Flutter's hot reload works for most UI changes:

1. Make changes to `lib/` files
2. Save file (or press `r` in terminal running `flutter run`)
3. Changes appear instantly without restarting app

**Limitations:** Hot reload does NOT work for:
- Changes to `main()` or service initialization
- Database schema changes
- Native code changes
- Asset changes (requires hot restart with `R`)

### Database Schema Changes

When modifying the database schema:

1. Increment `version` in `StorageService.init()`:
   ```dart
   _db = await openDatabase(
     '${appDir.path}/copyman.db',
     version: 4, // Was 3
     onCreate: _createTables,
     onUpgrade: _upgradeDatabase,
   );
   ```

2. Add migration logic in `_upgradeDatabase()`:
   ```dart
   if (oldVersion < 4) {
     await db.execute('ALTER TABLE clipboard_items ADD COLUMN my_column TEXT');
   }
   ```

3. Test migration:
   - Copy existing DB: `cp ~/.local/share/copyman/copyman.db ~/backup.db`
   - Run app (migration runs automatically)
   - Verify with: `sqlite3 ~/.local/share/copyman/copyman.db "PRAGMA user_version;"`

### Debugging

**Enable verbose logging:**
```dart
// In main.dart
import 'package:flutter/foundation.dart';

void main() {
  if (kDebugMode) {
    print("Debug mode enabled");
  }
  // ...
}
```

**SQLite query logging:**
```dart
// In storage_service.dart
await db.execute('SELECT * FROM clipboard_items');
print("Query executed");
```

**Keyboard event logging:**
```dart
// In home_screen.dart KeyboardListener
onKeyEvent: (event) {
  print("Key: ${event.logicalKey.keyLabel}");
  // ...
}
```

---

## Adding New Features

### Example: Adding a New Keyboard Shortcut

Let's add a "Copy & Delete" action bound to `Ctrl+Shift+Enter`.

#### Step 1: Add Action to Enum

**File:** `lib/services/hotkey_config_service.dart`

```dart
enum AppAction {
  // ... existing actions
  copyAndDelete, // Add this
}
```

#### Step 2: Add Default Binding

```dart
static const Map<AppAction, HotkeyBinding> _defaults = {
  // ... existing defaults
  AppAction.copyAndDelete: HotkeyBinding(
    key: LogicalKeyboardKey.enter,
    ctrl: true,
    shift: true,
  ),
};
```

#### Step 3: Add Display Name

```dart
static String actionDisplayName(AppAction action) {
  switch (action) {
    // ... existing cases
    case AppAction.copyAndDelete: return 'Copy & Delete';
  }
}
```

#### Step 4: Handle Action in UI

**File:** `lib/screens/home_screen.dart`

```dart
KeyboardListener(
  onKeyEvent: (event) {
    if (event is! KeyDownEvent) return;

    // ... existing handlers

    if (HotkeyConfigService.instance.matches(AppAction.copyAndDelete, event)) {
      _handleCopyAndDelete();
    }
  },
  // ...
)
```

#### Step 5: Implement Handler

```dart
Future<void> _handleCopyAndDelete() async {
  if (_selectedItem == null) return;

  // Copy to clipboard
  await Clipboard.setData(ClipboardData(text: _selectedItem!.content));
  _clipboardService.setLastContent(_selectedItem!.content);

  // Delete from database
  await StorageService.instance.deleteItem(_selectedItem!.id);

  // Refresh UI
  await _loadItems();

  // Close window
  await windowManager.hide();
}
```

#### Step 6: Test

1. Run app: `flutter run -d linux`
2. Open window: `Ctrl+Alt+V`
3. Select item
4. Press `Ctrl+Shift+Enter`
5. Verify item is copied and deleted

---

## Build Process

### Debug Build

Fast, includes debugging symbols, hot reload enabled.

```bash
flutter run -d linux
# or
flutter build linux --debug
```

**Output:** `build/linux/x64/debug/bundle/copyman`

### Release Build

Optimized, smaller binary, no debugging.

#### Linux (Standard)

```bash
flutter build linux --release
```

#### Linux (with Clang Workaround)

If you encounter linker issues (`ld not found`), use this workaround:

**Setup (one-time):**
```bash
mkdir -p ~/bin
cat > ~/bin/clang++ << 'EOF'
#!/bin/bash
exec /usr/lib/llvm-18/bin/clang++ "$@"
EOF
chmod +x ~/bin/clang++
ln -sf /usr/bin/ld ~/bin/ld
```

**Build:**
```bash
CC=$HOME/bin/clang CXX=$HOME/bin/clang++ LD=$HOME/bin/ld \
PATH=$HOME/bin:$PATH \
flutter build linux --release
```

**Why?** Flutter's build system resolves symlinks and expects `ld` in the same directory as `clang++`. The workaround ensures both are in `~/bin`.

#### macOS

```bash
flutter build macos --release
```

**Output:** `build/macos/Build/Products/Release/copyman.app`

#### Windows

```bash
flutter build windows --release
```

**Output:** `build/windows/runner/Release/copyman.exe`

### Build Script

Create a `build-and-run.sh` script for quick iteration:

```bash
#!/bin/bash
set -e

echo "Building CopyMan..."
CC=$HOME/bin/clang CXX=$HOME/bin/clang++ LD=$HOME/bin/ld \
PATH=$HOME/bin:$PATH \
flutter build linux --release

echo "Running CopyMan..."
./build/linux/x64/release/bundle/copyman
```

---

## Testing

### Unit Tests

Run all tests:
```bash
flutter test
```

Run specific test file:
```bash
flutter test test/services/fuzzy_search_test.dart
```

### Integration Tests

CopyMan currently has minimal integration tests. Contributions welcome.

**Manual Testing Checklist:**
- [ ] Clipboard monitoring captures new text
- [ ] Search filters items correctly
- [ ] Pin/unpin toggles work
- [ ] Groups filter items
- [ ] Sequential paste advances through items
- [ ] Hotkeys trigger correct actions
- [ ] Settings persist after restart
- [ ] App exclusions block password managers
- [ ] TTL auto-cleanup removes old items

### Linting

Run Dart analyzer:
```bash
flutter analyze lib/
```

Auto-format code:
```bash
dart format lib/
```

---

## Common Issues

### Issue: Clipboard Not Capturing (Linux)

**Symptom:** CopyMan doesn't detect copied text.

**Fix:**
```bash
sudo apt-get install xdotool x11-utils xclip
```

### Issue: Hotkey Not Working

**Symptom:** `Ctrl+Alt+V` doesn't show window.

**Possible Causes:**
1. Another app is using the same hotkey
2. Desktop environment blocks global hotkeys
3. CopyMan crashed silently

**Fix:**
- Check `journalctl -xe | grep copyman` for errors
- Change hotkey in Settings > Shortcuts
- Restart CopyMan: `pkill copyman && ./copyman`

### Issue: Database Locked

**Symptom:** App crashes with "database is locked" error.

**Fix:**
```bash
pkill copyman
rm ~/.local/share/copyman/copyman.db-wal
rm ~/.local/share/copyman/copyman.db-shm
```

### Issue: High Memory Usage

**Symptom:** CopyMan uses >100MB RAM.

**Possible Causes:**
1. Too many items in history (default: 500)
2. Memory leak in debug mode

**Fix:**
- Lower history limit: Settings > General > History Limit
- Build release version: `flutter build linux --release`

### Issue: Flutter Build Fails with Linker Error

**Symptom:** `ld: cannot find -lstdc++` or similar.

**Fix:** Use the [clang workaround](#linux-with-clang-workaround) described above.

---

## Performance Tips

1. **Profile Before Optimizing:**
   ```bash
   flutter run --profile
   ```

2. **Check Build Size:**
   ```bash
   du -sh build/linux/x64/release/bundle/
   ```

3. **Analyze Startup Time:**
   Add to `main()`:
   ```dart
   final stopwatch = Stopwatch()..start();
   await StorageService.instance.init();
   print('DB init: ${stopwatch.elapsedMilliseconds}ms');
   ```

4. **Reduce Polling Frequency:**
   If CPU usage is high, increase `ClipboardService.pollInterval` from 500ms to 1000ms.

---

## Code Style Guidelines

1. **Follow Effective Dart:** https://dart.dev/guides/language/effective-dart
2. **Use trailing commas:** Improves auto-formatting
   ```dart
   ClipboardItem(
     id: 1,
     content: "hello", // <- trailing comma
   );
   ```
3. **Prefer `final` over `var`:** Immutability by default
4. **Avoid abbreviations:** `ClipboardService` not `ClipSrv`
5. **Document public APIs:** Add dartdoc comments for all public methods
   ```dart
   /// Fetches clipboard items from the database.
   ///
   /// Returns up to [limit] items, optionally filtered by [search].
   Future<List<ClipboardItem>> fetchItems({String? search, int limit = 200});
   ```

---

## Resources

- **Flutter Docs:** https://docs.flutter.dev/
- **Dart Language Tour:** https://dart.dev/guides/language/language-tour
- **sqflite_common_ffi:** https://pub.dev/packages/sqflite_common_ffi
- **window_manager:** https://pub.dev/packages/window_manager
- **hotkey_manager:** https://pub.dev/packages/hotkey_manager

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

For questions or discussions, open an issue at:
https://github.com/richeshgupta/CopyMan/issues

---

**Last Updated:** 2026-02-06
**CopyMan Version:** 0.1.0 (Phase 2 Complete)
