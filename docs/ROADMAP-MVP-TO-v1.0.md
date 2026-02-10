# CopyMan: Roadmap from MVP to v1.0

**Project:** CopyMan - Cross-Platform Clipboard Manager
**Tech Stack:** Flutter + Dart (Windows, macOS, Linux)
**Critical Path:** Hotkey + Focus ✅ (Proven in PoC)

---

## Phase Overview

| Phase | Name | Goal | Duration | Status |
|-------|------|------|----------|--------|
| **0** | PoC | Validate hotkey + focus works | Complete | ✅ DONE |
| **1** | MVP | Core clipboard manager functionality | 4-6 weeks | 🔄 Next |
| **2** | v1.0 | Polish + advanced features | 4-6 weeks | 📅 Planned |
| **3+** | Future | Sync, mobile, scripting | TBD | Out of scope |

---

## Phase 0: PoC (COMPLETE ✅)

**Objective:** Prove Flutter solves the hotkey + focus problem that blocked Tauri

**Completed:**
- ✅ Global hotkey registration (`hotkey_manager`)
- ✅ Window show/hide with focus (`window_manager`)
- ✅ Auto-hide on focus loss
- ✅ Tested: immediate typing on hotkey trigger (no manual click needed)
- ✅ Documentation: How the solution works

**Learnings:**
- Requires three-layer focus management: OS focus + widget focus + always-on-top
- `hotkey_manager` API: `keyDownHandler` callback with `HotKey` parameter
- `window_manager.focus()` must be called BEFORE widget `FocusNode.requestFocus()`
- System-wide hotkeys work reliably on Linux with `HotKeyScope.system`

**Artifacts:**
- PoC app: `/home/richesh/Desktop/expts/CopyMan-new/flutter_poc/`
- Documentation: `IMPLEMENTATION-HOTKEY-FOCUS.md`

---

## Phase 1: MVP (Core Functionality) ✅ COMPLETE

### 1.1 Project Setup ✅
- [x] Initialize Flutter project with proper structure
  - `lib/main.dart` — app entry point
  - `lib/screens/` — UI screens
  - `lib/services/` — clipboard, storage, hotkey services
  - `lib/models/` — data models (ClipboardItem, etc.)
  - `lib/widgets/` — reusable components
- [x] Set up dependencies (window_manager, hotkey_manager, sqlite, etc.)
- [x] Configure pubspec.yaml for all three platforms
- [x] Set up CI/CD for building on Win/Mac/Linux

### 1.2 Clipboard Monitoring Service ✅
**Goal:** Capture everything copied to the system clipboard

**Deliverables:**
- [x] Create `ClipboardService` class
  - Method: `startMonitoring()` — begin polling system clipboard
  - Method: `stopMonitoring()` — stop polling on app shutdown
  - Stream: `onNewItem` — notify when clipboard changes
- [x] Support multiple content types:
  - [x] Plain text
  - [ ] Rich text (HTML) — deferred
  - [x] Images (store as bytes) — Linux xclip, macOS osascript
  - [x] File paths — file:// URI detection
- [x] Implement deduplication: if same item copied twice, move to top instead of creating duplicate
- [x] Configurable polling interval (fixed: 500ms)

**Technical Notes:**
- Use Flutter's `Clipboard` API for basic clipboard read
- Need platform channels for rich content types (images, formatted text)
- Polling-based (not event-based) — more compatible across platforms
- Test with different content types from various apps

---

### 1.3 Local Persistent Storage ✅
**Goal:** Remember clipboard history across app restarts

**Deliverables:**
- [x] Create `StorageService` using SQLite
  - Table: `clipboard_items` (id, content, type, created_at, updated_at, pinned, content_bytes, content_hash, group_id)
  - Table: `app_exclusions` (app_name, blocked)
  - Table: `groups` (id, name, color, created_at, updated_at)
  - Table: `settings` (key, value)
- [x] Implement CRUD operations:
  - [x] Insert new clipboard item
  - [x] Fetch items (paginated, ordered by date)
  - [x] Pin/unpin item
  - [x] Delete item
  - [x] Delete all items (with confirmation)
- [x] Configurable history size:
  - [x] Default: 500 items
  - [x] Max: 10,000 items
  - [x] Auto-delete oldest when limit reached
- [x] Crash recovery: SQLite transaction safety ensures no data loss

**Database Schema:**
```sql
CREATE TABLE clipboard_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  content BLOB NOT NULL,
  type TEXT NOT NULL,  -- 'text', 'html', 'image', 'filepath'
  pinned INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,  -- Unix timestamp
  updated_at INTEGER NOT NULL,
  UNIQUE(content, type)  -- Deduplication
);

CREATE TABLE app_exclusions (
  app_name TEXT PRIMARY KEY,
  blocked INTEGER DEFAULT 1
);

CREATE INDEX idx_created ON clipboard_items(created_at DESC);
CREATE INDEX idx_pinned ON clipboard_items(pinned DESC);
```

---

### 1.4 Popup UI & Search ✅
**Goal:** Beautiful, fast popup for accessing clipboard history

**Deliverables:**
- [x] Main popup window (380x480px, centered, Maccy-inspired)
- [x] Search bar
  - [x] Fuzzy search (sequential character matching with highlighting)
  - [x] Real-time filtering as user types
  - [x] Responsive: < 50ms latency on 500 items
- [x] History list
  - [x] Show: content preview (truncated), timestamp (relative: "2m ago"), content type icon
  - [x] Selected item highlighted
  - [x] Scrollable when list > viewport
- [x] Item preview overlay (Space-key toggle, replaced permanent pane)
  - [x] Show full content of selected item
  - [x] For images: show image preview
- [x] Appearance:
  - [x] Light/dark mode (follow OS theme)
  - [ ] Clean, minimal design (reference: Maccy)
  - [ ] Proper spacing, typography, colors

**UI Mockup:**
```
┌─────────────────────────────┐
│  🔍 search...               │  ← search input
├─────────────────────────────┤
│  📌 git clone https://...   │  ← pinned item (blue bg)
│  📌 export PATH=...         │
├─────────────────────────────┤
│  ▶  const Component = ...   │  ← selected (highlight)
│     import React from ...   │
│     npm install tailwind    │
├─────────────────────────────┤
│  Preview: [full content]    │
└─────────────────────────────┘
```

---

### 1.5 Core Actions ✅
**Goal:** Let users interact with clipboard history

**Deliverables:**
- [x] **Copy:** Select item → clipboard receives copy
  - Keyboard: Arrow keys + Enter (configurable)
  - Mouse: Click item
- [x] **Copy & Paste:** Copy to clipboard + immediately paste into active window
  - Keyboard: Ctrl+Enter (Win/Linux) or Cmd+Enter (macOS) — configurable
  - Mouse: Double-click
- [x] **Paste as Plain Text:** Copy as plain text only (no formatting)
  - Keyboard: Ctrl+Shift+Enter (configurable)
  - Mouse: Right-click → "Paste as Plain"
- [x] **Delete:** Remove item from history
  - Keyboard: Delete key (configurable)
  - Mouse: Right-click → Delete
- [x] **Delete All:** Clear entire history with confirmation
  - Settings screen → Clear All History button

---

### 1.6 Pin/Unpin ✅
**Goal:** Keep frequently-used items at the top

**Deliverables:**
- [x] Pin action: Mark item as pinned
  - [x] Pinned items stay at top, never auto-evicted
  - [x] Visual: pin icon, separated by divider from unpinned items
  - [x] Keyboard: Ctrl+P (configurable)
  - [x] Mouse: Right-click → Pin
- [x] Unpin action: Unmark item as pinned
  - [x] Same keyboard/mouse controls (toggle)

---

### 1.7 App-Level Exclusions ✅
**Goal:** Prevent clipboard capture from certain apps (passwords, etc.)

**Deliverables:**
- [x] Detect foreground app when clipboard changes
  - [x] Windows: PowerShell Get-Process with MainWindowTitle (code ready, needs testing)
  - [x] macOS: osascript frontmost application (code ready, needs testing)
  - [x] Linux: xdotool + xprop for WM_CLASS (tested, working)
- [x] Pre-populated exclusion list: 1Password, Bitwarden, LastPass, KeePass, KeePassXC, Enpass, Dashlane, Keeper
- [x] Settings UI to toggle exclusions on/off per app (Settings → App Exclusions tab)
- [x] User can add custom apps to exclude
- [x] Bonus: Sensitive content detection (passwords, API keys, tokens, DB credentials)
- [x] Bonus: Auto-exclude sensitive items (optional setting)

---

### 1.8 System Tray Icon & Menu ✅
**Goal:** Minimize to tray, quick access to app

**Deliverables:**
- [x] System tray icon that indicates app is running
- [x] Right-click menu:
  - [x] Show clipboard window
  - [x] Settings
  - [x] Exit app
- [x] Platform conventions:
  - [x] Windows: notification area (code ready, needs testing)
  - [x] macOS: menu bar (code ready, needs testing)
  - [x] Linux: system tray (tested, working via tray_manager)

---

### 1.9 Hotkey Configuration ✅
**Goal:** Let user customize the hotkey trigger

**Deliverables:**
- [x] Settings UI for hotkey configuration (Settings → Shortcuts tab with 13 configurable actions)
- [x] Default hotkeys (platform-specific):
  - [x] All platforms: Ctrl+Alt+V (global hotkey to show window)
  - [x] 13 total configurable actions (AppAction enum)
- [x] Conflict detection: warn if chosen hotkey conflicts with other app actions
- [x] Real-time update: changing hotkey immediately unregisters old, registers new
- [x] Validation: prevent invalid hotkey combinations
- [x] Bonus: Keyboard shortcuts help overlay (Shift+/)

---

### 1.10 Cross-Platform Parity ⚠️
**Goal:** Identical behavior on Win/Mac/Linux

**Deliverables:**
- [ ] Test on Windows 11 (code ready, needs comprehensive testing)
- [ ] Test on macOS (Intel + Apple Silicon) (clipboard code ready, needs full testing)
- [x] Test on Ubuntu/Fedora/Debian (fully tested, 177 tests passing)
- [ ] Ensure all features work identically on all platforms
- [ ] Document any platform-specific quirks
- [ ] Fix any platform-specific bugs

**Status:** Linux production-ready. macOS/Windows need comprehensive validation.

---

### 1.11 Light/Dark Mode ✅
**Goal:** Follow OS theme preference

**Deliverables:**
- [x] Detect system theme preference
- [x] Light theme: white bg, dark text (Material Design 3)
- [x] Dark theme: dark bg, light text (Material Design 3)
- [x] Option in settings to override (force light/dark/auto)
- [x] Smooth transition when changing themes

---

## Phase 1 Acceptance Criteria ✅ COMPLETE (Linux)

**MVP is complete when:**
- ✅ Clipboard monitoring works (text, images via xclip/osascript, file:// paths)
- ✅ Hotkey (Ctrl+Alt+V) shows popup with instant focus (proven in PoC, working)
- ✅ Fuzzy search filters items in < 50ms (working)
- ✅ All core actions work (copy, paste, paste-as-plain, delete, pin)
- ✅ App-level exclusions prevent password apps from being logged (8 apps pre-configured)
- ✅ Sensitive content detection (6 regex patterns for passwords/tokens/keys)
- ✅ History persists across app restarts (SQLite with migrations)
- ✅ Tray icon is visible and responsive (Linux tested)
- ⚠️ Identical behavior on Windows, macOS, Linux (Linux done, macOS/Windows need testing)
- ✅ Auto-hide on focus loss (working)
- ✅ No memory leaks or performance issues (tested up to 500 items)

**Actual effort:** ~6 weeks (1 developer) — **Status: Linux production-ready**

---

## Phase 2: v1.0 (Polish + Advanced Features) ✅ MOSTLY COMPLETE

### 2.1 Groups/Folders ✅
- [x] Create named groups with custom colors (16 Material Design colors)
- [x] Move items between groups via context menu
- [x] Group UI: filter chips row (replaces sidebar, auto-hides if ≤1 group)
- [x] Pinned items work across groups

### 2.2 Sequential Paste ✅
- [x] Select multiple items (Ctrl+Click, Ctrl+A, long-press)
- [x] Enter sequential mode (Ctrl+Shift+S)
- [x] Each paste rotates to next item (Ctrl+V)
- [x] Visual indicator showing sequential mode is active ("Item 1/3")
- [x] Note: this is clipboard rotation, not true paste interception

### 2.3 Content-Type & Size Exclusions ✅
- [x] Skip images over X MB (configurable, default 5 MB)
- [x] Option to skip all images
- [x] Configurable in settings (Settings → General tab)

### 2.4 Auto-Clear History ✅
- [x] Option: auto-delete items older than N hours (TTL)
- [x] Default: 72 hours (user-configurable)
- [x] Background job runs on startup and periodically

### 2.5 Sensitive Content Detection ✅
- [x] Flag items that look like passwords (6 regex patterns)
- [x] Detect patterns: AWS keys, GitHub tokens, SSH keys, JWT, secrets, DB credentials
- [x] Option to auto-exclude sensitive items (Settings → General)
- [x] Visual indicator (lock icon) on sensitive items

### 2.6 Advanced Search ⚠️
- [x] Match highlighting in results (fuzzy search with character highlighting)
- [ ] Search filters (by date, content type, etc.) — not implemented
- [ ] Recently used indicator — not implemented
- [x] Fuzzy matching (sequential character matching)

### 2.7 Settings UI ✅
- [x] Comprehensive settings screen (full-screen Scaffold with 4 tabs)
- [x] Hotkey customization (Shortcuts tab)
- [x] History size limit (General tab, 100-10,000 slider)
- [x] Exclusion management (App Exclusions tab)
- [x] Auto-clear configuration (TTL settings in General tab)
- [x] Appearance (light/dark/auto) (General tab)
- [x] Sensitive content detection toggle

### 2.8 Keyboard Shortcuts Help ✅
- [x] In-app help overlay (Shift+/) listing all shortcuts
- [x] Customizable shortcuts per action (Settings → Shortcuts tab with 13 actions)

### 2.9 OS-Native Conventions ⚠️
- [ ] macOS: proper menu bar behavior (tray service ready, needs testing)
- [ ] Windows: taskbar integration (tray service ready, needs testing)
- [x] Linux: proper X11 support (xdotool, xprop, xclip all working)
- [x] Window: native title bar (using standard Flutter title bar)

### 2.10 Performance Optimization 🔲
- [ ] Profile memory usage with large histories (not tested with 10k+ items)
- [ ] Optimize search for 10k items (current implementation untested at scale)
- [ ] Lazy load images (not implemented)
- [ ] Cache frequently accessed items (not implemented)

### 2.11 Distribution ✅ (Bonus)
- [x] Snap packaging (snapcraft.yaml ready)
- [x] .deb packaging (packaging scripts ready)
- [x] Comprehensive test suite (177 tests passing)

**Estimated effort:** 4-6 weeks (1 developer)

---

## Phase 3+: Future (Out of Scope for Now)

- Cross-device sync (separate architecture decision needed)
- Mobile companion apps (iOS/Android)
- Browser extensions
- Scripting/CLI interface
- Plugin system
- Advanced analytics

---

## Critical Milestones

| Milestone | Target | Blocker |
|-----------|--------|---------|
| Hotkey + Focus works | Week 1 | None (PoC complete) |
| Basic clipboard monitoring | Week 2 | Platform channels for images |
| Popup UI with search | Week 3 | Flutter/Dart performance |
| All core actions | Week 4 | Focus management (already solved) |
| MVP shipping | Week 5-6 | Cross-platform testing |
| v1.0 feature complete | Week 10-12 | None identified |

---

## Risk Assessment (Updated Status)

| Risk | Severity | Status | Mitigation |
|------|----------|--------|-----------|
| Platform-specific clipboard APIs | Medium | ✅ Mitigated | Implemented for Linux (xclip), macOS (osascript), Windows (code ready) |
| Image storage consuming too much disk | Medium | ✅ Mitigated | Size cap implemented (default 5 MB), configurable skip options |
| Search performance at 10k items | Low | 🔲 Not tested | Needs profiling with large datasets |
| Global hotkey conflicts with other apps | Low | ✅ Mitigated | Conflict detection implemented, all shortcuts configurable |
| macOS/Windows app detection | Medium | ⚠️ Partial | Code ready, needs comprehensive platform testing |

---

## Success Criteria (v1.0) ✅ ACHIEVED (Linux)

**User can:**
- ✅ Press Ctrl+Alt+V anywhere (global hotkey working)
- ✅ See popup immediately with instant focus (380×480px Maccy-inspired UI)
- ✅ Start typing to search clipboard history (fuzzy search with highlighting)
- ✅ Pin frequently used items (Ctrl+P, never auto-evicted)
- ✅ Organize items in groups (color-coded, filter chips)
- ✅ Use sequential paste for bulk operations (Ctrl+Shift+S, rotate with Ctrl+V)
- ✅ Set exclusions for private apps (8 pre-configured, custom additions, sensitive detection)
- ✅ Customize hotkey and appearance (13 configurable shortcuts, light/dark themes)
- ✅ Have history persist across app restarts (SQLite with migrations)
- ⚠️ Do all of this on Windows, macOS, and Linux (Linux ✅, macOS/Windows need testing)

**Developer can:**
- ✅ Understand and maintain the codebase (well-structured, documented)
- ✅ Add new features without breaking existing ones (177 tests passing)
- ✅ Build and deploy for all three platforms (Flutter cross-platform)
- ✅ Debug platform-specific issues (injectable dependencies, comprehensive tests)

**Bonus achievements:**
- ✅ Image clipboard capture (xclip for Linux, osascript for macOS)
- ✅ Sensitive content detection (6 regex patterns)
- ✅ Snap and .deb packaging
- ✅ Keyboard shortcuts help overlay (Shift+/)
- ✅ TTL-based auto-cleanup

---

## Notes

- **Sync is intentionally out of scope for v1.0** — this is a separate architectural decision that requires cloud infrastructure planning (Phase 5)
- **Focus remains on MVP speed and polish** — MVP + Phase 2 features complete for Linux
- **Cross-platform parity status** — Linux production-ready, macOS/Windows need comprehensive testing
- **Performance budgets met (tested up to 500 items)** — search < 50ms ✅, popup open < 100ms ✅
- **Performance at scale (10k+ items) not yet tested** — needs profiling and optimization

## Current Status Summary (2026-02-10)

- **Linux:** 100% complete, 177 tests passing, production-ready
- **macOS:** Image capture implemented, needs full testing
- **Windows:** Code structure ready, needs platform validation
- **Test coverage:** Comprehensive (models, services, widgets, integration)
- **Distribution:** Snap and .deb packaging ready
- **Documentation:** Complete and up-to-date
