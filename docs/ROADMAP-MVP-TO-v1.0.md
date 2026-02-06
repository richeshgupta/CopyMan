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

## Phase 1: MVP (Core Functionality)

### 1.1 Project Setup
- [ ] Initialize Flutter project with proper structure
  - `lib/main.dart` — app entry point
  - `lib/screens/` — UI screens
  - `lib/services/` — clipboard, storage, hotkey services
  - `lib/models/` — data models (ClipboardItem, etc.)
  - `lib/widgets/` — reusable components
- [ ] Set up dependencies (window_manager, hotkey_manager, sqlite, etc.)
- [ ] Configure pubspec.yaml for all three platforms
- [ ] Set up CI/CD for building on Win/Mac/Linux

### 1.2 Clipboard Monitoring Service
**Goal:** Capture everything copied to the system clipboard

**Deliverables:**
- [ ] Create `ClipboardService` class
  - Method: `startMonitoring()` — begin polling system clipboard
  - Method: `stopMonitoring()` — stop polling on app shutdown
  - Callback: `onClipboardChanged(ClipboardItem item)` — notify when clipboard changes
- [ ] Support multiple content types:
  - [ ] Plain text
  - [ ] Rich text (HTML)
  - [ ] Images (store as bytes)
  - [ ] File paths
- [ ] Implement deduplication: if same item copied twice, move to top instead of creating duplicate
- [ ] Configurable polling interval (default: 500ms, min: 200ms, max: 2000ms)

**Technical Notes:**
- Use Flutter's `Clipboard` API for basic clipboard read
- Need platform channels for rich content types (images, formatted text)
- Polling-based (not event-based) — more compatible across platforms
- Test with different content types from various apps

---

### 1.3 Local Persistent Storage
**Goal:** Remember clipboard history across app restarts

**Deliverables:**
- [ ] Create `StorageService` using SQLite
  - Table: `clipboard_items` (id, content, type, created_at, updated_at, pinned)
  - Table: `app_exclusions` (app_name, blocked)
- [ ] Implement CRUD operations:
  - [ ] Insert new clipboard item
  - [ ] Fetch items (paginated, ordered by date)
  - [ ] Pin/unpin item
  - [ ] Delete item
  - [ ] Delete all items (with confirmation)
- [ ] Configurable history size:
  - [ ] Default: 500 items
  - [ ] Max: 10,000 items
  - [ ] Auto-delete oldest when limit reached
- [ ] Crash recovery: ensure no data loss if app crashes mid-write

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

### 1.4 Popup UI & Search
**Goal:** Beautiful, fast popup for accessing clipboard history

**Deliverables:**
- [ ] Main popup window (400x500px, centered)
- [ ] Search bar
  - [ ] Fuzzy search (not just substring)
  - [ ] Real-time filtering as user types
  - [ ] Responsive: < 50ms latency on 500 items
- [ ] History list
  - [ ] Show: content preview (truncated), timestamp (relative: "2m ago"), content type icon
  - [ ] Selected item highlighted
  - [ ] Scrollable when list > viewport
- [ ] Item preview pane
  - [ ] Show full content of selected item
  - [ ] For images: show thumbnail
- [ ] Appearance:
  - [ ] Light/dark mode (follow OS theme)
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

### 1.5 Core Actions
**Goal:** Let users interact with clipboard history

**Deliverables:**
- [ ] **Copy:** Select item → clipboard receives copy
  - Keyboard: Arrow keys + Enter
  - Mouse: Click item
- [ ] **Copy & Paste:** Copy to clipboard + immediately paste into active window
  - Keyboard: Ctrl+Enter (Win/Linux) or Cmd+Enter (macOS)
  - Mouse: Double-click
- [ ] **Paste as Plain Text:** Copy as plain text only (no formatting)
  - Keyboard: Ctrl+Shift+V (Win/Linux) or Cmd+Shift+V (macOS)
  - Mouse: Right-click → "Paste as Plain"
- [ ] **Delete:** Remove item from history
  - Keyboard: Delete key
  - Mouse: Right-click → Delete
- [ ] **Delete All:** Clear entire history with confirmation
  - Right-click → "Delete All" → confirm dialog

---

### 1.6 Pin/Unpin
**Goal:** Keep frequently-used items at the top

**Deliverables:**
- [ ] Pin action: Mark item as pinned
  - [ ] Pinned items stay at top, never auto-evicted
  - [ ] Visual: different background color or icon
  - [ ] Keyboard: P key
  - [ ] Mouse: Right-click → Pin
- [ ] Unpin action: Unmark item as pinned
  - [ ] Same keyboard/mouse controls (toggle)

---

### 1.7 App-Level Exclusions
**Goal:** Prevent clipboard capture from certain apps (passwords, etc.)

**Deliverables:**
- [ ] Detect foreground app when clipboard changes
  - [ ] Windows: Use Win32 API `GetForegroundWindow()`
  - [ ] macOS: Use Cocoa `NSWorkspace.frontmostApplication`
  - [ ] Linux: Use X11 `xdotool getactivewindow` or similar
- [ ] Pre-populated exclusion list: 1Password, Bitwarden, LastPass, KeePass, etc.
- [ ] Settings UI to toggle exclusions on/off per app
- [ ] Auto-discover: List apps that have written to clipboard since install
- [ ] User can add custom apps to exclude

**Note:** This requires platform channels for native app detection.

---

### 1.8 System Tray Icon & Menu
**Goal:** Minimize to tray, quick access to app

**Deliverables:**
- [ ] System tray icon that indicates app is running
- [ ] Right-click menu:
  - [ ] Show clipboard window
  - [ ] Settings
  - [ ] Exit app
- [ ] Platform conventions:
  - [ ] Windows: notification area (bottom-right)
  - [ ] macOS: menu bar (top-right)
  - [ ] Linux: system tray (if available)

---

### 1.9 Hotkey Configuration
**Goal:** Let user customize the hotkey trigger

**Deliverables:**
- [ ] Settings UI for hotkey configuration
- [ ] Default hotkeys (platform-specific):
  - [ ] Windows: Ctrl+Shift+V or Ctrl+Alt+V
  - [ ] macOS: Cmd+Shift+V or Cmd+Option+V
  - [ ] Linux: Ctrl+Shift+V or Ctrl+Alt+V
- [ ] Conflict detection: warn if chosen hotkey conflicts with other apps
- [ ] Real-time update: changing hotkey immediately unregisters old, registers new
- [ ] Validation: prevent invalid hotkey combinations

**Note:** Avoid Ctrl+Shift+V (paste-as-plain-text in many apps) as default.

---

### 1.10 Cross-Platform Parity
**Goal:** Identical behavior on Win/Mac/Linux

**Deliverables:**
- [ ] Test on Windows 11
- [ ] Test on macOS (Intel + Apple Silicon)
- [ ] Test on Ubuntu/Fedora/Debian
- [ ] Ensure all features work identically on all platforms
- [ ] Document any platform-specific quirks
- [ ] Fix any platform-specific bugs

---

### 1.11 Light/Dark Mode
**Goal:** Follow OS theme preference

**Deliverables:**
- [ ] Detect system theme preference
- [ ] Light theme: white bg, dark text
- [ ] Dark theme: dark bg, light text
- [ ] Option in settings to override (force light/dark/auto)
- [ ] Smooth transition when changing themes

---

## Phase 1 Acceptance Criteria

**MVP is complete when:**
- ✅ Clipboard monitoring works (text, images, files)
- ✅ Hotkey (Ctrl+Alt+V) shows popup with instant focus (proven in PoC)
- ✅ Fuzzy search filters items in < 50ms
- ✅ All core actions work (copy, paste, delete, pin)
- ✅ App-level exclusions prevent password apps from being logged
- ✅ History persists across app restarts
- ✅ Tray icon is visible and responsive
- ✅ Identical behavior on Windows, macOS, Linux
- ✅ Auto-hide on focus loss
- ✅ No memory leaks or performance issues

**Estimated effort:** 4-6 weeks (1 developer)

---

## Phase 2: v1.0 (Polish + Advanced Features)

### 2.1 Groups/Folders
- [ ] Create named groups
- [ ] Move items between groups
- [ ] Group UI: sidebar or collapsible sections
- [ ] Pinned items across groups

### 2.2 Sequential Paste
- [ ] Select multiple items
- [ ] Enter sequential mode
- [ ] Each paste rotates to next item
- [ ] Visual indicator showing sequential mode is active
- [ ] Note in UI: this is clipboard rotation, not true paste interception

### 2.3 Content-Type & Size Exclusions
- [ ] Skip images over X MB
- [ ] Option to skip all images
- [ ] Option to skip files
- [ ] Configurable in settings

### 2.4 Auto-Clear History
- [ ] Option: auto-delete items older than N days
- [ ] Default: 30 days (user-configurable)
- [ ] Background job runs on startup

### 2.5 Sensitive Content Detection
- [ ] Flag items that look like passwords
- [ ] Detect patterns from password managers
- [ ] Option to auto-exclude sensitive items
- [ ] Visual indicator (lock icon) on sensitive items

### 2.6 Advanced Search
- [ ] Match highlighting in results
- [ ] Search filters (by date, content type, etc.)
- [ ] Recently used indicator
- [ ] Fuzzy matching improvements

### 2.7 Settings UI
- [ ] Comprehensive settings screen
- [ ] Hotkey customization
- [ ] History size limit
- [ ] Exclusion management
- [ ] Auto-clear configuration
- [ ] Appearance (light/dark/auto)
- [ ] About / Version

### 2.8 Keyboard Shortcuts Help
- [ ] In-app help screen listing all shortcuts
- [ ] Customizable shortcuts per action

### 2.9 OS-Native Conventions
- [ ] macOS: proper menu bar behavior
- [ ] Windows: taskbar integration
- [ ] Linux: proper X11/Wayland support
- [ ] Window: native title bar vs custom

### 2.10 Performance Optimization
- [ ] Profile memory usage with large histories
- [ ] Optimize search for 10k items
- [ ] Lazy load images
- [ ] Cache frequently accessed items

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

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Platform-specific clipboard APIs | Medium | Use platform channels early, test on all three OS |
| Image storage consuming too much disk | Medium | Implement size cap and compression |
| Search performance at 10k items | Low | Lazy load, index, optimize |
| Global hotkey conflicts with other apps | Low | Warn user, make configurable |
| macOS/Linux detection of foreground app | Medium | Platform channels, test thoroughly |

---

## Success Criteria (v1.0)

**User can:**
- ✅ Press Ctrl+Alt+V anywhere
- ✅ See popup immediately with instant focus
- ✅ Start typing to search clipboard history
- ✅ Pin frequently used items
- ✅ Organize items in groups
- ✅ Use sequential paste for bulk operations
- ✅ Set exclusions for private apps
- ✅ Customize hotkey and appearance
- ✅ Have history persist across app restarts
- ✅ Do all of this on Windows, macOS, and Linux

**Developer can:**
- ✅ Understand and maintain the codebase
- ✅ Add new features without breaking existing ones
- ✅ Build and deploy for all three platforms
- ✅ Debug platform-specific issues

---

## Notes

- **Sync is intentionally out of scope for v1.0** — this is a separate architectural decision that requires cloud infrastructure planning
- **Focus remains on MVP speed and polish** — don't add features that aren't in the PRD
- **Cross-platform parity is non-negotiable** — test on all three OS before each release
- **Performance budgets are real** — search < 50ms, popup open < 100ms
