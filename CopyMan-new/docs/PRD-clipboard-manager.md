# CopyMan — Product Requirements Document

**Version:** 2.0
**Date:** 2026-02-04
**Status:** Draft

---

## 1. Executive Summary

CopyMan is a cross-platform clipboard manager for Windows, macOS, and Linux. The clipboard manager market has a clear gap: the best tools on each platform are platform-locked (Maccy on macOS, Ditto on Windows, Greenclip on Linux), while the only true cross-platform option (CopyQ) sacrifices polish for power. CopyMan targets the space between Maccy's simplicity and CopyQ's depth — a fast, keyboard-first, visually clean clipboard manager that works identically on every OS, with enough power for developers without the configuration overhead of CopyQ. Cross-device sync is a first-class feature, not an afterthought.

---

## 2. Competitive Landscape

### 2.1 Competitor Profiles

| Tool | Platform | Source | Strength | Weakness |
|---|---|---|---|---|
| **Maccy** | macOS only | Open (MIT) | Speed, keyboard UX, privacy | No cross-platform, no folders, no sequential paste |
| **CopyQ** | Win/Mac/Linux | Open (GPL) | Scripting, tabs, CLI, cross-platform | Complex UI, configuration overhead, less polished |
| **Ditto** | Windows only | Open | LAN sync between Windows machines, mature | Windows only, older UI |
| **CleanClip** | macOS only | Closed | Smart lists, sequential paste, rich search | Paid, macOS only |
| **Greenclip** | Linux only | Open | Lightweight, Rofi integration | Linux only, minimal feature set |
| **ClipboardMaster** | Windows only | Freemium | Large history (10k), password safe | Windows only, bloated |
| **ClipCascade** | Win/Mac/Linux/Android | Open (GPL) | Hybrid P2P + server sync, self-hostable, E2EE | Not a clipboard manager UI — sync-only utility |

### 2.2 What the Market Gets Wrong

- **Maccy** is the UX gold standard but is deliberately minimal. No folders, no sequential paste, limited app-level exclusion rules. Maccy 2.0 addresses storage and performance but stays macOS-only.
- **CopyQ** is the only real cross-platform contender but its UI feels dated and its power comes at the cost of discoverability. Search is buried behind a toolbar button.
- **Ditto** has excellent LAN sync across Windows machines but zero story outside Windows.
- **ClipCascade** solves cross-device sync well (hybrid P2P + relay, self-hostable, encrypted) but it is a sync utility, not a clipboard manager. It has no history UI, no search, no pinning.
- No existing open-source tool delivers all of: cross-platform + fast search + clean UI + keyboard-first + cross-device sync (in a single product).

### 2.3 CopyMan's Position

CopyMan takes Maccy's UX philosophy (fast, keyboard-driven, opinionated) and extends it with cross-platform support, organized history, and cross-device sync. It does not aim to be CopyQ (no scripting engine, no plugin system). It aims to be the clipboard manager that a developer reaching for on any machine immediately feels at home with — and that keeps their clipboard in sync across all of them.

---

## 3. User Personas

### 3.1 Developer / Power User (Primary)
- Copies code snippets, API keys, terminal commands, URLs constantly throughout the day.
- Switches between machines (e.g., laptop + desktop, or Mac + Linux workstation).
- Wants instant search, paste-without-formatting, and the ability to pin reusable snippets.
- Values keyboard shortcuts over mouse interaction.
- Needs clipboard history to follow them across devices seamlessly.

### 3.2 General Productivity User (Secondary)
- Copies text, images, links during research or writing.
- Wants a clean, unobtrusive popup that doesn't interrupt workflow.
- Needs basic organization (pin favorites) but not deep folder hierarchies.
- Expects the app to "just work" with zero configuration.

### 3.3 Privacy-Conscious User (Constraint)
- Does not want clipboard data leaving the machine unless explicitly opted in.
- Expects passwords and sensitive data to be automatically excluded or clearly flagged.
- Prefers local-only storage by default. If sync is enabled, expects end-to-end encryption so no intermediate server can read their data.

---

## 4. Core Requirements

Priority levels: **P0** = must ship in MVP, **P1** = must ship in 1.0, **P2** = post-1.0.

### 4.1 Clipboard Capture & History

| ID | Requirement | Priority |
|---|---|---|
| REQ-01 | Monitor the system clipboard continuously and store every copied item. | P0 |
| REQ-02 | Support multiple content types: plain text, rich text/HTML, images, file paths. | P0 |
| REQ-03 | Configurable history size (default: 500 items, max: 10,000). | P0 |
| REQ-04 | Persist history to local storage. History survives app restarts. | P0 |
| REQ-05 | Deduplicate: moving an existing item to the top on re-copy instead of creating a duplicate entry. | P0 |
| REQ-06 | Clipboard monitoring must detect changes with a latency no greater than 1 second under normal use. | P1 |

### 4.2 Retrieval & Search

| ID | Requirement | Priority |
|---|---|---|
| REQ-10 | Open the clipboard popup via a global keyboard shortcut (default: configurable per OS). | P0 |
| REQ-11 | Instant, as-you-type fuzzy search across all history. Must feel responsive at 10,000 items (< 50ms perceived latency). | P0 |
| REQ-12 | Search matches against content, not just the most recent items. | P0 |
| REQ-13 | Selecting an item copies it to the system clipboard. | P0 |
| REQ-14 | A dedicated "copy and paste" action: copies the selected item and immediately pastes it into the active window. | P0 |
| REQ-15 | Paste without formatting (plain text only) as a distinct action. | P0 |

### 4.3 Organization & Pinning

| ID | Requirement | Priority |
|---|---|---|
| REQ-20 | Pin items to the top of the list. Pinned items are never auto-evicted by history size limits. | P0 |
| REQ-21 | Unpin action available on pinned items. | P0 |
| REQ-22 | Visual distinction between pinned and unpinned items in the popup. | P0 |
| REQ-23 | Group/folder support: user can create named groups and move items into them. | P1 |
| REQ-24 | Groups appear as a sidebar or collapsible sections in the popup. | P1 |

### 4.4 Privacy & Security

| ID | Requirement | Priority |
|---|---|---|
| REQ-30 | All history stored locally by default. No network calls, no telemetry unless explicitly enabled. | P0 |
| REQ-31 | App-level exclusion list: user can block clipboard capture from specific applications. | P0 |
| REQ-32 | Content-type exclusion: user can choose to not store images, or not store items over a size threshold. | P1 |
| REQ-33 | Auto-clear option: history older than N days is purged automatically. | P1 |
| REQ-34 | Sensitive-content detection: items copied from known password managers are flagged and optionally excluded by default. | P1 |
| REQ-35 | When cross-device sync is enabled, all data in transit and at rest on any relay server must be end-to-end encrypted. The encryption key must never leave the user's devices. | P1 |

### 4.5 UI & UX

| ID | Requirement | Priority |
|---|---|---|
| REQ-40 | Popup appears as a floating panel near the cursor or in a fixed position (user-configurable). | P0 |
| REQ-41 | Popup dismisses on Escape or on click-outside. | P0 |
| REQ-42 | Full keyboard navigation: arrow keys, Enter to select, shortcuts for pin/delete. | P0 |
| REQ-43 | Preview pane: show a truncated preview of the selected item's content. | P0 |
| REQ-44 | Configurable appearance: light/dark mode, follows OS theme by default. | P0 |
| REQ-45 | System tray / menu bar icon indicating CopyMan is running. | P0 |
| REQ-46 | Sequential paste mode: copy multiple items in sequence, then paste them one-by-one in order. | P1 |
| REQ-47 | Synced items are visually distinguishable from locally-copied items (e.g., a subtle sync indicator). | P1 |

### 4.6 Cross-Platform Parity

| ID | Requirement | Priority |
|---|---|---|
| REQ-50 | Identical feature set and keyboard shortcut semantics on Windows, macOS, and Linux. | P0 |
| REQ-51 | Default keyboard shortcut uses OS-appropriate modifier keys (Ctrl on Win/Linux, Cmd on macOS). | P0 |
| REQ-52 | Native clipboard API usage on each platform (no emulation). | P0 |
| REQ-53 | Tray icon integration follows each OS convention (system tray on Windows, menu bar on macOS, tray on Linux). | P1 |

---

## 5. Detailed Feature Specifications

### 5.1 Clipboard Popup

The popup is the primary interaction surface. It is a narrow, focused panel — not a full window.

```
┌─────────────────────────────┐
│  🔍 search...               │  ← instant fuzzy search input
├─────────────────────────────┤
│  📌 git clone https://...   │  ← pinned (distinct style)
│  📌 export default App {    │  ← pinned
├─────────────────────────────┤
│  ▶  const x = useState(0)   │  ← most recent, selected
│     import React from ...   │
│     npm install tailwindcss │
│     ...                     │
└─────────────────────────────┘
  [Copy] [Copy & Paste] [Plain]     ← action bar (keyboard-accessible)
```

- Width: fixed (e.g., 380px). Height: grows with content, max ~60% of screen height, then scrolls.
- Items show: content type icon, truncated first line (or image thumbnail), timestamp relative ("2m ago").
- Selected item highlighted. Preview of full content shown below list or in a side panel if item is long.

### 5.2 Search Behavior

- Fuzzy match, not substring-only. Typing "gclone" should surface "git clone https://...".
- Match highlighting: the matched portions of the content are bolded/highlighted in the list.
- Search is scoped to visible history + pinned items by default. No toggle needed.
- Search state resets on popup close.

### 5.3 Pinning

- Pinned items live in a dedicated section at the top of the popup, separated by a divider.
- Pinned items are not subject to history eviction (REQ-20).
- No hard limit on pinned items, but UI should degrade gracefully (scrollable section) beyond ~20.

### 5.4 App-Level Exclusions

- Settings screen lists all apps that have written to the clipboard since install, with a toggle.
- When an excluded app is the active foreground app at the time of a clipboard write, CopyMan skips capture.
- Common exclusions pre-filled: known password managers (1Password, Bitwarden, LastPass, KeePass).

### 5.5 Sequential Paste

- User enters "sequential mode" via a shortcut or toggle.
- In sequential mode, CopyMan rotates clipboard content: after each paste, it loads the next item from the queue into the system clipboard automatically.
- The queue is populated by the user selecting multiple items (shift-select or multi-select) before entering sequential mode.
- Visual indicator in the tray icon or popup that sequential mode is active.
- Note: this is clipboard rotation, not true paste interception. It will not work reliably in apps that overwrite the clipboard on their own (e.g., some IDEs on auto-save). This limitation must be communicated clearly in the UI.

### 5.6 History Item Actions (Context Menu)

Right-click or a shortcut on a selected item reveals:
- Copy
- Copy & Paste
- Paste as Plain Text
- Pin / Unpin
- Move to Group
- Delete
- Delete All (with confirmation)

---

## 6. Non-Functional Requirements

| Category | Requirement |
|---|---|
| **Performance** | Popup open latency < 100ms. Search response < 50ms perceived latency on 10k items. |
| **Memory** | Background memory footprint < 30MB with 10k items in history. |
| **Storage** | Local persistent storage with crash recovery. No data loss if the app is killed mid-write. |
| **Binary size** | Application binary should be reasonably small. Avoid bundling an entire browser engine if the platform provides one natively. |
| **Startup** | App startup (tray icon visible) < 1 second on a mid-range machine. |
| **Reliability** | Clipboard monitoring must survive the foreground app crashing. |
| **Accessibility** | Full keyboard navigability. No action requires a mouse. |
| **Privacy** | Zero outbound network traffic by default. No analytics. Sync is opt-in only. |

---

## 7. Cross-Device Sync

This section defines the requirements and evaluates the architecture options for syncing clipboard history across a user's devices. Sync is opt-in. It is off by default and activates only when the user explicitly configures it.

### 7.1 Why Sync Matters

A developer working across a laptop and a desktop — or across a Mac and a Linux workstation — loses context every time they switch machines. The system clipboard resets. History is local. This is the single biggest limitation shared by Maccy, CopyQ, CleanClip, and Greenclip. Ditto solves it, but only between Windows machines on the same LAN. Microsoft's built-in clipboard sync solves it between Windows and Android, but routes data through Microsoft's cloud with no end-to-end encryption. There is no existing tool that gives a developer private, cross-platform, cross-network clipboard sync out of the box as part of a full clipboard manager.

### 7.2 Sync Architecture Options

Four architectural approaches exist in production today. Each has been evaluated against the requirements of a privacy-conscious developer.

#### Option A — Cloud Relay (third-party hosted)

How it works: every clipboard write is uploaded to a cloud server, which pushes it to all other devices signed in to the same account.

Real-world example: Microsoft's clipboard sync (Windows ↔ Android). Data passes through Microsoft's servers. Microsoft states it is not stored permanently, but it is not end-to-end encrypted — Microsoft can read clipboard contents in transit.

| Pros | Cons |
|---|---|
| Works across any network without configuration | Data transits a third-party server in readable form |
| No self-hosting required | Vendor lock-in |
| Broad device support (if vendor supports it) | Latency: 2–3 seconds reported in practice |

**Verdict:** Does not meet the privacy requirement (REQ-35). Ruled out as the default path.

---

#### Option B — Local Network P2P (LAN only)

How it works: devices discover each other on the local network and exchange clipboard data directly, with no server involved.

Real-world examples: Apple Universal Clipboard (Bluetooth + Wi-Fi, expires after 2 minutes), KDE Connect (Linux ↔ Android over LAN).

| Pros | Cons |
|---|---|
| Zero server involvement — fully private | Devices must be on the same network |
| Ultra-low latency (sub-second) | No sync when devices are on different networks |
| No account or sign-up required | Device discovery can be flaky across OS types |

**Verdict:** Excellent for the on-network case. Insufficient alone — a developer away from home loses sync entirely.

---

#### Option C — Zero-Knowledge Cloud Relay (self-hostable)

How it works: clipboard data is encrypted on the source device before it is sent to a relay server. The relay stores and forwards only ciphertext. The encryption key never leaves the user's devices. The relay server can be self-hosted or provided by a third party.

Real-world examples: ClipCascade (server mode), Planck (AES-256-GCM + PBKDF2), ViClip.

| Pros | Cons |
|---|---|
| Works across any network | Requires a server (self-hosted or managed) |
| Server cannot read the data (E2EE) | Adds infrastructure responsibility if self-hosted |
| Self-hostable — no vendor dependency | Key management must be handled correctly |
| Latency is acceptable (< 2s on good connections) | |

**Verdict:** Meets privacy requirements. Works off-network. Self-hosting is a realistic option for the developer persona.

---

#### Option D — Hybrid: LAN P2P + Zero-Knowledge Relay (recommended)

How it works: devices first attempt direct P2P sync on the local network (fast, no server). If devices are on different networks, sync falls back to a zero-knowledge relay server.

Real-world example: ClipCascade operates in this exact mode — P2P when on the same network, relay when not. The relay is self-hostable via Docker.

| Pros | Cons |
|---|---|
| Best of both worlds: fast on LAN, available off-network | Most complex to implement of the four options |
| Fully private: E2EE on relay path, no server on LAN path | Self-hosted relay adds a dependency |
| Self-hostable relay — no vendor lock-in | |
| Aligns with how ClipCascade already works (proven architecture) | |

**Verdict:** Recommended. This is the architecture CopyMan should target for sync.

### 7.3 Sync Requirements

| ID | Requirement | Priority |
|---|---|---|
| REQ-60 | Sync is off by default. User must explicitly enable it in settings. | P1 |
| REQ-61 | When on the same local network, devices sync directly (P2P) without routing through any server. | P1 |
| REQ-62 | When devices are on different networks, sync routes through a relay server. The relay receives only encrypted data. | P1 |
| REQ-63 | The encryption key is derived from a user-controlled secret (e.g., a passphrase or generated key). It is never transmitted to the relay server. | P1 |
| REQ-64 | The relay server is self-hostable. CopyMan must document how to run one, and provide a simple deployment path (e.g., a single container or binary). | P1 |
| REQ-65 | Synced items appear in the clipboard history on all devices. They are visually marked as synced (REQ-47). | P1 |
| REQ-66 | Pinned items sync across devices. | P2 |
| REQ-67 | Sync supports text, images, and file paths. | P1 |
| REQ-68 | There is a per-item size cap for sync (configurable, default: 1 MB). Items over the cap are not synced and the user is notified. | P1 |
| REQ-69 | Devices can be paired without an account. Pairing is done via a shared key or passphrase, not an email/password sign-up flow. | P2 |
| REQ-70 | CopyMan provides an optional managed relay option (hosted by the CopyMan team or a third party) for users who do not want to self-host. This is clearly labeled as a hosted option. | P2 |

### 7.4 Sync — What Is Out of Scope

- Syncing to iOS or Android devices is P2 (requires companion mobile apps, which is a separate product effort).
- Conflict resolution for simultaneous edits to the same pinned item is out of scope for 1.0. Last-write-wins is acceptable.
- The relay server does not need to store history — it can be a pure pass-through. Long-term history storage is local only.

### 7.5 Encryption Specification (Non-Binding)

This section states the encryption properties CopyMan must provide, without prescribing a specific algorithm. The chosen algorithm must satisfy all of the following:

- Authenticated encryption (confidentiality + integrity in one pass).
- Symmetric key size of at least 256 bits.
- Key derivation from a user passphrase must use a memory-hard KDF (to resist brute force).
- Nonce/IV must be unique per encryption operation and must not be reused.
- The relay server receives: encrypted ciphertext + nonce. Nothing else.

These properties are satisfied by several well-regarded schemes (e.g., AES-256-GCM, ChaCha20-Poly1305). The final choice is an implementation decision, not a product decision.

---

## 8. Competitive Gap Analysis — What CopyMan Fills

| Feature | Maccy | CopyQ | Ditto | ClipCascade | **CopyMan** |
|---|---|---|---|---|---|
| Cross-platform (Win/Mac/Linux) | No | Yes | No | Yes (sync only) | **Yes** |
| Keyboard-first, fast popup | Yes | Partial | Partial | No UI | **Yes** |
| Fuzzy search | No (substring) | Yes | Regex only | No UI | **Yes** |
| Pin / Favorites | Yes | Yes | Yes | No | **Yes** |
| Groups / Folders | No | Yes (tabs) | No | No | **Yes (1.0)** |
| Sequential paste | No | Yes | No | No | **Yes (1.0)** |
| App-level exclusions | Limited | Yes | No | No | **Yes** |
| Paste as plain text | Yes | Yes | Yes | No | **Yes** |
| Local-only by default | Yes | Yes | Yes | Yes | **Yes** |
| Cross-device sync | No | No | LAN/Windows only | Yes (utility) | **Yes (1.0)** |
| E2EE sync | N/A | N/A | No | Yes | **Yes** |
| Self-hostable sync relay | N/A | N/A | N/A | Yes | **Yes** |
| Clean, modern UI | Yes | No | No | N/A | **Yes** |
| Scripting / CLI | No | Yes | No | No | **No (out of scope)** |
| Open source | Yes | Yes | Yes | Yes | **Yes** |

---

## 9. MVP Scope (Phase 1) vs. 1.0 (Phase 2)

### Phase 1 — MVP (all P0 requirements)
- Clipboard monitoring across all three platforms (text + images).
- Persistent local history (500 items default, configurable up to 10k).
- Fuzzy search popup with full keyboard navigation.
- Pin / unpin items.
- Copy, copy-and-paste, paste-as-plain-text actions.
- App-level exclusion list (pre-seeded with common password managers).
- Light/dark mode following OS theme.
- System tray / menu bar icon.
- Configurable global shortcut.
- Identical feature behavior on Windows, macOS, and Linux.

### Phase 2 — 1.0 Release (all P1 requirements)
- Groups / folders.
- Sequential paste.
- Content-type and size exclusions.
- Auto-clear old history (configurable TTL).
- Sensitive-content flagging.
- **Cross-device sync:** LAN P2P + zero-knowledge relay, self-hostable, E2EE.
- OS-native tray icon conventions per platform.
- Sync indicator on synced items.

### Phase 3 — Post-1.0 (P2 / Future)
- Managed relay option (hosted).
- Account-free device pairing via shared key.
- Pinned item sync across devices.
- Mobile companion apps (iOS, Android).
- Scripting or macro engine (if demand warrants).

---

## 10. Open Questions

1. **Default shortcut conflict:** `Ctrl+Shift+V` is paste-as-plain-text in Chrome, VS Code, and many Linux apps. The default shortcut needs testing on all three platforms to avoid collisions. A prominent configuration step at first launch is recommended regardless.
2. **Linux desktop environment scope:** Clipboard access and foreground app detection behave differently under Wayland vs. X11. Which Linux desktop environments are in-scope for MVP needs to be defined early.
3. **Image storage budget:** Storing thousands of full-resolution images will consume significant local storage. A per-image size cap or a total image storage budget needs to be defined (e.g., store only a thumbnail + reference, or cap total image storage at 100 MB).
4. **Sequential paste limitation:** Clipboard rotation does not work reliably in apps that overwrite the clipboard independently. The UX must communicate this limitation to users upfront.
5. **Sync relay hosting:** For Phase 2, a decision is needed on whether CopyMan ships a self-hostable relay binary/container, or partners with an existing relay service. ClipCascade's relay is open source and proven — evaluate whether it can be reused or adapted vs. building from scratch.
6. **Sync pairing UX:** Pairing devices via a shared passphrase is simpler than account-based flows but requires the user to manually enter or scan a key on each device. Evaluate QR-code-based pairing as a discoverability improvement.

---

## 11. Sources & References

- [Maccy GitHub](https://github.com/p0deje/Maccy) — primary UX reference; keyboard-first philosophy
- [Maccy 2.0 Discussion](https://github.com/p0deje/Maccy/discussions/790) — SwiftUI/SwiftData rewrite, future roadmap
- [CopyQ GitHub](https://github.com/hluk/CopyQ) — cross-platform reference; tabs and scripting architecture
- [Ditto GitHub](https://github.com/sabrogden/Ditto) — Windows baseline; LAN sync design
- [ClipCascade GitHub](https://github.com/Sathvik-Rao/ClipCascade) — hybrid P2P + relay sync architecture, self-hostable, E2EE
- [XDA: Self-Hosted Clipboard Sync](https://www.xda-developers.com/self-host-own-clipboard-sync-and-works-across-every-device-own/) — ClipCascade self-hosting walkthrough
- [Zapier: Best Clipboard Managers](https://zapier.com/blog/best-clipboard-managers/) — market overview
- [Windows Forum: Best Clipboard Managers 2026](https://windowsforum.com/threads/best-clipboard-managers-for-windows-11-in-2026-ditto-copyq-clipclip-and-more.391369/) — Windows competitive landscape
- [CleanClip: Mac Clipboard Manager Comparison](https://cleanclip.cc/articles/best-clipboard-managers-mac-2024) — macOS competitive analysis
