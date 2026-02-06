# CopyMan — Cross-Platform Clipboard Manager

**Project Status:** Ready for MVP Development
**Tech Stack:** Flutter + Dart (Windows, macOS, Linux)
**Current Phase:** Moving from PoC to MVP

---

## What is CopyMan?

A fast, beautiful, cross-platform clipboard manager that keeps your clipboard history instantly searchable and accessible via a global hotkey. Unlike competitors that are platform-locked or have fundamental usability issues, CopyMan is:

- **Fast:** Popup opens instantly, search responds in < 50ms
- **Beautiful:** Modern UI, native-feeling on all platforms
- **Lightweight:** ~40 MB binary, < 30 MB idle memory
- **Reliable:** Hotkey + keyboard focus work correctly
- **Private:** All data stored locally by default

---

## Documentation

### Core Documents
1. **[IMPLEMENTATION-HOTKEY-FOCUS.md](./IMPLEMENTATION-HOTKEY-FOCUS.md)** — How we solved the hotkey + focus problem that blocked Tauri
   - Three-layer focus management architecture
   - `hotkey_manager` API reference
   - `window_manager` integration
   - PoC test results

2. **[DECISION-FLUTTER-OVER-TAURI.md](./DECISION-FLUTTER-OVER-TAURI.md)** — Why we chose Flutter instead of Tauri/Electron
   - Problem analysis: Tauri's hotkey + focus failure
   - Solution: Flutter's three-layer focus management
   - Risk assessment and mitigation
   - Timeline and financial impact

3. **[ROADMAP-MVP-TO-v1.0.md](./ROADMAP-MVP-TO-v1.0.md)** — Phase-wise plan from MVP to v1.0
   - Phase 0 (PoC): Complete ✅
   - Phase 1 (MVP): Core functionality (4-6 weeks)
   - Phase 2 (v1.0): Advanced features (4-6 weeks)
   - Critical milestones and acceptance criteria

### Reference Documents
- **[PRD-clipboard-manager.md](./PRD-clipboard-manager.md)** — Product Requirements Document
  - Feature specifications
  - Non-functional requirements
  - Competitive analysis
  - Cross-device sync architecture options (out of scope for v1.0)

- **[cider-technical-assessment.md](./cider-technical-assessment.md)** — Analysis of Cider (Apple Music client)
  - Cross-platform architecture patterns
  - Comparison with CopyMan's approach

---

## Quick Start

### Prerequisites
- Flutter SDK (tested with 3.38.9)
- Dart SDK (included with Flutter)
- platform-specific tools:
  - Windows: Visual Studio Build Tools
  - macOS: Xcode Command Line Tools
  - Linux: clang, cmake, ninja-build, libgtk-3-dev, etc.

### Running the PoC
```bash
cd flutter_poc
flutter pub get
flutter run -d linux  # or windows, macos
```

### Building for Release
```bash
flutter build linux    # Build for Linux
flutter build macos    # Build for macOS
flutter build windows  # Build for Windows
```

---

## Key Decisions Made

### Technology Stack
- **Frontend:** Flutter + Dart (not Tauri, not Electron)
- **Backend:** Dart/Flutter native code
- **Storage:** SQLite
- **Hotkey:** hotkey_manager plugin
- **Window Mgmt:** window_manager plugin

### Architecture
- Single Dart codebase for all platforms
- Three-layer focus management for reliability
- SQLite local storage with crash recovery
- Polling-based clipboard monitoring

### Out of Scope for v1.0
- Cross-device sync (requires cloud infrastructure)
- Mobile apps (iOS, Android)
- Browser extensions
- Scripting/CLI interface

---

## Development Phases

### Phase 1: MVP (4-6 weeks) — What's coming next
**Goal:** Core clipboard manager that works flawlessly

Must-have features:
- Global hotkey trigger (Ctrl+Alt+V)
- Clipboard monitoring (text, images, files)
- Persistent history (500-10k items)
- Fuzzy search
- Copy/paste actions
- Pin/unpin items
- App-level exclusions (passwords, etc.)
- Light/dark mode
- System tray icon
- Cross-platform parity (Win/Mac/Linux)

### Phase 2: v1.0 (4-6 weeks)
**Goal:** Polish and advanced features

New features:
- Groups/folders for organization
- Sequential paste (bulk operations)
- Content-type exclusions
- Auto-clear old history
- Sensitive content detection
- Advanced search with highlighting
- Settings UI
- Keyboard shortcut customization

### Phase 3+: Future
Out of scope for now:
- Cross-device sync
- Mobile apps
- Browser extensions
- Plugin system

---

## Risk Mitigation

| Risk | Probability | Severity | Mitigation |
|------|-------------|----------|-----------|
| Platform-specific clipboard APIs | Medium | Medium | Use platform channels early, test on all three OS |
| Search performance with 10k items | Low | Low | Indexing, lazy loading, optimization |
| Global hotkey conflicts with other apps | Low | Low | Make hotkey configurable, warn user |
| macOS/Linux app detection for exclusions | Medium | Low | Platform channels, early testing |

---

## Performance Targets

| Metric | Target | Status |
|--------|--------|--------|
| Popup open latency | < 100ms | On track |
| Search response | < 50ms (10k items) | Requires optimization |
| Background memory | < 30MB | On track |
| Startup time | < 1s | On track |
| Binary size | < 15MB (Linux) | ~40MB (acceptable) |

---

## Success Criteria

**User can:**
- Press Ctrl+Alt+V anywhere on their computer
- See the clipboard popup appear immediately
- Start typing to search their clipboard history
- Pin frequently-used items to the top
- Organize items in groups
- Use sequential paste for bulk operations
- Set exclusions to prevent password/private data capture
- Customize the hotkey and appearance
- Have all their history persist across app restarts
- Do all of this identically on Windows, macOS, and Linux

---

## Files & Structure

```
CopyMan-new/
├── docs/
│   ├── README.md (this file)
│   ├── IMPLEMENTATION-HOTKEY-FOCUS.md
│   ├── DECISION-FLUTTER-OVER-TAURI.md
│   ├── ROADMAP-MVP-TO-v1.0.md
│   ├── PRD-clipboard-manager.md
│   └── cider-technical-assessment.md
├── flutter_poc/
│   ├── lib/
│   │   └── main.dart (PoC implementation)
│   ├── pubspec.yaml
│   └── ... (Flutter project structure)
└── src/ (future: main app source code)
```

---

## Next Steps

1. **Immediate:** Review decision documents and roadmap
2. **This week:** Set up Flutter project structure
3. **Next weeks:** Follow Phase 1 roadmap
4. **Milestone:** MVP ready for beta testing in 4-6 weeks

---

## Questions?

Refer to:
- **"How does hotkey + focus work?"** → IMPLEMENTATION-HOTKEY-FOCUS.md
- **"Why Flutter and not Tauri?"** → DECISION-FLUTTER-OVER-TAURI.md
- **"What's the plan?"** → ROADMAP-MVP-TO-v1.0.md
- **"What features are in MVP?"** → PRD-clipboard-manager.md

---

**Last Updated:** 2026-02-05
**Status:** Ready for MVP development
**Team:** [Add team info]
