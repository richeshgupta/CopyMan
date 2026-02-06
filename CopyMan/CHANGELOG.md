# Changelog

All notable changes to CopyMan will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Maccy-inspired minimal keyboard-first interface
- Configurable keyboard shortcuts with conflict detection
- Space-key overlay for preview toggle (replaces permanent preview pane)
- Group filter chips row (replaces sidebar, auto-hides if ≤1 group)
- Shortcuts settings tab with key binding editor
- Pinned/unpinned item divider in list view
- Status bar showing item counts

### Changed
- Window size reduced from 420×580 to 380×480 pixels (~170px vertical reclaimed)
- Groups sidebar replaced with compact 32px filter chip row
- Settings dialog upgraded to full-screen Scaffold with 4 tabs
- Clipboard item tiles redesigned to single-row layout with reduced padding
- Navigation shortcuts now configuration-based instead of hardcoded

### Removed
- Permanent preview pane (replaced with Space-key toggle overlay)
- Bottom keyboard legend
- Info strip
- Fixed-width sidebar

## [2.1.0] - 2026-02-05

### Added
- Group color coding in sidebar and chips
- Settings screen with 4 tabs: General, Groups, Shortcuts, App Exclusions
- TTL-based auto-cleanup of old clipboard items
- App exclusion list editor in settings
- Group color picker with 16 Material Design colors
- Configurable history size slider (100-10000 items)
- Visual feedback for group colors throughout UI

### Changed
- Groups now support custom colors (16 preset options)
- Settings UI upgraded from placeholder to functional 4-tab interface
- App exclusions moved from database-only to user-editable UI
- Auto-cleanup runs on app startup and periodically

### Fixed
- Context menu actions properly scoped to prevent fall-through
- Group deletion now properly reassigns items to "Uncategorized"

## [2.0.0] - 2026-02-05

### Added
- Groups/folders for organizing clipboard items
- Sequential paste mode (multi-select items, paste one-by-one)
- Multi-select support with Ctrl+Click and Ctrl+A
- Group sidebar with item counts
- "Move to Group" context menu option
- Ctrl+Shift+S shortcut to start sequence mode
- Progress indicator for sequential paste ("Item 1/3")
- "Uncategorized" default group
- Long-press gesture for item multi-select
- Collapsible sidebar (responsive design)

### Changed
- Database schema upgraded from v2 to v3
- Home screen layout refactored to support sidebar + main content
- Clipboard item tiles enhanced with multi-select checkboxes
- Keyboard shortcut handling expanded for new features

### Fixed
- Group filtering performance optimized with indexed queries
- Multi-selection state now properly cleared after operations

## [1.0.0] - 2026-02-05

### Added
- Real-time clipboard history capture (500ms polling)
- Fuzzy search with character highlighting
- Pin/unpin clipboard items
- Context menu (copy, paste, paste as plain, pin, delete)
- Global hotkey (Ctrl+Alt+V) to toggle window
- System tray icon with menu
- App-level exclusions (password managers pre-configured)
- Dark and light themes following system preference
- SQLite database for persistent storage
- Preview pane showing full content of selected item
- Configurable history size limit (data layer)
- Support for plain text pasting (removes formatting)

### Technical
- Flutter 3.38.9 + Dart 3.10.8
- SQLite with sqflite_common_ffi 2.3.7+1
- Material Design 3 theming
- Cross-platform window management
- Linux-specific app detection (xdotool/xprop)
- Fuzzy search algorithm with sequential matching
- Database schema v2 with migration support

### Security
- Password manager exclusions (8 apps pre-configured)
- Local-only storage (no network sync in v1.0)
- No sensitive data logged
- App detection with fallback safety

[Unreleased]: https://github.com/richeshgupta/CopyMan/compare/master...ui-redesign-maccy-inspired
[2.1.0]: https://github.com/richeshgupta/CopyMan/compare/fe54295...5676b8e
[2.0.0]: https://github.com/richeshgupta/CopyMan/compare/e54ff81...fe54295
[1.0.0]: https://github.com/richeshgupta/CopyMan/releases/tag/v1.0.0
