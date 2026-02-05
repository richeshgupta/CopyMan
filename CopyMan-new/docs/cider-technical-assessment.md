# Cider — Technical Assessment Report

**Date:** 2026-02-04
**Source:** https://cider.sh/
**Subject:** Tech stack analysis and cross-platform architecture

---

## 1. What is Cider

Cider is a cross-platform desktop Apple Music client built by Cider Collective. It started as "Apple Music Electron" (now deprecated), evolved into Cider v1 (open source, now archived), and is currently on **Cider 2** — a closed-source, performance-focused rewrite with a completely new codebase.

The project is maintained by an international team and funded via Open Collective. As of the time of this assessment, Cider 2 is at version 3.1.0 with 13,500+ active users.

---

## 2. Project Evolution

| Generation | Status | Source | Notes |
|---|---|---|---|
| Apple Music Electron | Deprecated | Was open source | Original proof of concept |
| Cider v1 | Archived (Dec 2024) | Open source (AGPL-3.0) | 7.2k GitHub stars, 98 contributors |
| Cider 2 | Active | Closed source | Current version; GitHub repo used for issue tracking only |

---

## 3. Tech Stack

### 3.1 Frontend

| Technology | Role |
|---|---|
| **Vue.js** | Core UI framework — reactive, component-based rendering |
| **TypeScript** | Primary language — adds static type checking over JavaScript |
| **Quasar** | Vue-based UI component library (used in v1; role in v2 unclear) |

### 3.2 Backend / App Shell

| Technology | Platform | Role |
|---|---|---|
| **Electron** | macOS, Linux | Desktop app shell; bundles Chromium + Node.js |
| **.NET + WebView2** | Windows | Native Windows app shell; replaces Electron on Windows |

### 3.3 Auxiliary / Supporting Services

| Technology | Purpose |
|---|---|
| **Go** | Lightweight artwork processing server |
| **Go** | Chromecast audio streaming integration |
| **Socket.io** | Real-time communication (client ↔ backend) |
| **MusicKit.js** | Apple's official JS library for Apple Music playback and metadata |

### 3.4 Cider v1 Stack (for reference)

Vue.js 2, Electron.js, Webpack, JavaScript (81%), EJS templates, Less/CSS, pnpm package manager.

---

## 4. Cross-Platform Architecture

Cider uses a **split-backend strategy** — one shared frontend, two distinct native backends depending on the OS.

```
┌─────────────────────────────────────────────┐
│              Vue.js + TypeScript             │
│         (shared UI layer — all platforms)    │
└───────────────┬─────────────┬───────────────┘
                │             │
       ┌────────▼──────┐  ┌───▼────────────────┐
       │   Electron    │  │  .NET + WebView2   │
       │ (macOS/Linux) │  │    (Windows)       │
       └───────────────┘  └────────────────────┘
```

### Why two backends instead of one?

- **Electron on macOS/Linux:** Electron embeds Chromium and Node.js, giving full access to OS APIs on Unix-like systems. It is the de-facto standard for cross-platform desktop apps on these platforms.
- **.NET + WebView2 on Windows:** WebView2 is Microsoft's Chromium-based embedded browser control for .NET apps. Using it on Windows instead of Electron gives:
  - Smaller binary size (no bundled Chromium — WebView2 is shared across the OS).
  - Deeper native Windows integration (COM APIs, shell integration, Windows notification center, etc.).
  - Lower memory overhead compared to a full Electron instance.

The Vue.js/TypeScript frontend code is shared across both backends. The backend difference is transparent to the UI layer — it just renders the same Vue app inside different host shells.

### Platform matrix

| Platform | App Shell | WebView Engine | Notes |
|---|---|---|---|
| Windows | .NET 8 (WPF or WinForms) | WebView2 (Chromium) | Native Windows look & feel |
| macOS | Electron | Chromium (bundled) | Cocoa integration via Electron |
| Linux | Electron | Chromium (bundled) | GTK integration via Electron |

---

## 5. Integrations and Features

| Category | Details |
|---|---|
| **Music Services** | Apple Music (via MusicKit.js) |
| **Social / Scrobbling** | Discord (RPC), Last.fm, Spotify |
| **Audio** | Spatialization, Adrenaline Processor (proprietary EQ/DSP), equalizer |
| **Remote Control** | Cider Remote — iOS app to control playback |
| **Extensibility** | Plugin system + theme marketplace |
| **Casting** | Chromecast support via Go-based service |

---

## 6. Known Technical Limitations

These stem from constraints in Apple's MusicKit.js API, which Cider depends on for playback:

- **No lossless audio** — MusicKit.js cannot decrypt lossless streams. The team is building a proprietary MusicKit replacement, but it is not yet available.
- **No crossfade** — Audio session management in MusicKit.js does not support overlapping tracks.
- **No smart playlists** — Smart Playlist logic lives in Apple's proprietary backend; no public API is exposed.

---

## 7. Relevance to CopyMan

Cider's architecture was initially considered for CopyMan as a Tauri + Svelte reference, but evaluation showed that **Tauri's focus-handling limitations make it unsuitable for a clipboard manager** (see `DECISION-FLUTTER-OVER-TAURI.md`). CopyMan instead uses **Flutter (Dart)**, which provides:

| Concern | Cider's Approach | CopyMan's Approach (Flutter) |
|---|---|---|
| App shell | Electron (macOS/Linux) + .NET/WebView2 (Windows) | Flutter (Dart + native Skia rendering) |
| Frontend | Vue.js + TypeScript | Dart + Material Design 3 |
| Native backend | Split per OS | Single Dart codebase (Flutter handles platform differences) |
| Binary size | Large (Electron bundles Chromium) | ~30–40 MB (includes Skia, no WebView overhead) |
| Hotkey + focus | Not evaluated (Electron native support) | ✅ Works reliably on all platforms |
| Clipboard access | Varies per platform | ✅ Native API, no WebView limitations |
| Global hotkey handling | Not evaluated | ✅ `hotkey_manager` plugin; reliable system-level integration |

Flutter's native rendering avoids WebView focus issues that plague Tauri and Electron for clipboard managers. See `DECISION-FLUTTER-OVER-TAURI.md` for the technical decision rationale and PoC results.

---

## 8. Sources

- https://cider.sh/
- https://github.com/ciderapp/Cider — v1 source (archived)
- https://github.com/ciderapp/Cider-2 — v2 issue tracker
- https://github.com/ciderapp — Cider Collective org
