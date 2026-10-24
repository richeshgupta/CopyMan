# CopyMan Repository

Welcome to the CopyMan project repository. This repository contains the CopyMan clipboard manager and related documentation.

## 📦 What's Inside

### CopyMan — Cross-Platform Clipboard Manager
A lightweight, fast, and feature-rich clipboard manager for Linux, Windows, and macOS. Built with Flutter for a native desktop experience.

**Status:** ✅ Phase 2 Complete | **License:** MIT | **Built with:** Flutter 3.38.9

[![GitHub release](https://img.shields.io/github/v/release/richeshgupta/CopyMan)](https://github.com/richeshgupta/CopyMan/releases)
[![GitHub downloads](https://img.shields.io/github/downloads/richeshgupta/CopyMan/total)](https://github.com/richeshgupta/CopyMan/releases)
[![Tests](https://img.shields.io/badge/tests-177%20passing-brightgreen)](https://github.com/richeshgupta/CopyMan)

**Platform Support:**
- ✅ **Linux:** Production-ready (.deb, Snap)
- ✅ **macOS:** Supported (.dmg) — clipboard images, paste, app detection via osascript
- 🔄 **Windows:** Code structure ready, requires platform validation

---

## 📥 Installation

### Linux (Ubuntu/Debian)

#### Method 1: One-Line Installer (Recommended)
The easiest way to install CopyMan:
```bash
curl -sSL https://raw.githubusercontent.com/richeshgupta/CopyMan/master/install.sh | bash
```

This will automatically:
- Download the latest .deb package
- Install CopyMan and its dependencies
- Set up the application

#### Method 2: Download .deb Package
```bash
wget https://github.com/richeshgupta/CopyMan/releases/download/v0.1.0/copyman_0.1.0_amd64.deb
sudo dpkg -i copyman_0.1.0_amd64.deb
sudo apt-get install -f  # Install dependencies if needed
```

#### Method 3: From GitHub Releases
1. Visit [Releases Page](https://github.com/richeshgupta/CopyMan/releases)
2. Download `copyman_0.1.0_amd64.deb`
3. Double-click the file to install (GUI method)
4. Or use: `sudo dpkg -i copyman_0.1.0_amd64.deb`

### macOS

#### Method 1: Download DMG (Recommended)
1. Download `copyman_0.1.0_macos.dmg` from the [Releases Page](https://github.com/richeshgupta/CopyMan/releases)
2. Open the DMG and drag **CopyMan** to **Applications**
3. On first launch, grant Accessibility permissions when prompted

#### Method 2: Build from Source
```bash
cd copyman
flutter pub get
flutter build macos --release
open build/macos/Build/Products/Release/CopyMan.app
```

### System Requirements

**Linux (Ubuntu 20.04+):**
- GTK 3.0+, xclip, xdotool, x11-utils
- Dependencies are automatically installed with the .deb package

**macOS (10.14 Mojave+):**
- No additional dependencies required (uses built-in osascript)
- Grant Accessibility permissions on first launch for paste simulation

### Wayland (Hyprland, Sway, GNOME)

CopyMan runs under XWayland, where global key grabs don't fire. Bind a key in your compositor to toggle the window with a signal instead:

```bash
pkill -USR1 -x copyman
```

Hyprland (Lua config): `o.bind("CTRL + ALT + V", "CopyMan", "pkill -USR1 -x copyman")`, plus a float rule for class `Com.richeshgupta.copyman`. Install `wl-clipboard` (and optionally `wtype`) so copies from native Wayland apps are captured.

### First Launch

After installation:

| | Linux | macOS |
|---|---|---|
| **Open CopyMan** | Ctrl+Alt+V | Control+Option+V |
| **System tray** | System tray icon | Menu bar icon |

Copy something to see it in the clipboard history!

### Quick Start

- **Open:** Ctrl+Alt+V (Linux) / Control+Option+V (macOS)
- **Search:** Just start typing
- **Copy:** Enter
- **Copy & Paste:** Ctrl+Enter / Control+Enter
- **Help:** Shift+/ (shows all shortcuts)

---

## 📚 Documentation

### Quick Links

| Document | Purpose |
|----------|---------|
| [**FEATURES & ARCHITECTURE**](./FEATURES_AND_ARCHITECTURE.md) | Complete feature list, tech stack, services, performance |
| [**CONTRIBUTING**](./CONTRIBUTING.md) | Contribution guidelines & development setup |
| [**DEVELOPMENT**](./docs/DEVELOPMENT.md) | Detailed development guide & architecture |
| [**SECURITY**](./SECURITY.md) | Security policy & data handling |
| [**CHANGELOG**](./CHANGELOG.md) | Release history & version changes |
| [**LICENSE**](./LICENSE) | MIT License |

### Getting Started

1. **New User?** Start with [FEATURES & ARCHITECTURE](./FEATURES_AND_ARCHITECTURE.md) for complete feature list and quick start
2. **Want to Contribute?** Read [CONTRIBUTING](./CONTRIBUTING.md) for setup & guidelines
3. **Developer?** See [DEVELOPMENT](./docs/DEVELOPMENT.md) for architecture & dev workflow
4. **Have a Security Concern?** Check [SECURITY](./SECURITY.md) for reporting process

---

## 🛠️ Build from Source

Want to build CopyMan yourself? See our [Development Guide](./docs/DEVELOPMENT.md) for detailed instructions.

**Quick build:**
```bash
cd copyman
flutter pub get
flutter build linux --release
./build/linux/x64/release/bundle/copyman
```

**For developers:**
```bash
cd copyman
flutter pub get
flutter run -d linux
```

---

## 🤝 Contributing

CopyMan is open source and welcomes contributions!

- **Report Issues:** [GitHub Issues](https://github.com/richeshgupta/CopyMan/issues)
- **Suggest Features:** [GitHub Discussions](https://github.com/richeshgupta/CopyMan/discussions)
- **Submit Code:** See [CONTRIBUTING](./CONTRIBUTING.md)

---

## 🗓️ Upcoming Plans

### Next Milestones

| Phase | Status | Features |
|-------|--------|----------|
| **Phase 2** | ✅ Complete | Keyboard-first UI, configurable shortcuts, groups, sequential paste, image capture |
| **Phase 3** | ✅ Complete | macOS support (osascript clipboard, paste, app detection, .dmg packaging) |
| **Phase 4** | 🔄 Testing | Windows support (code ready, requires comprehensive testing) |
| **Phase 5** | 📋 Future | Cross-device sync (LAN P2P, E2EE), cloud backup, mobile apps |

### Current Focus
- ✅ **Linux Production** — Fully functional, 177 tests passing, ready for daily use
- ✅ **macOS Release** — Image capture, paste, app detection via osascript, .dmg packaging
- 🔄 **Windows Testing** — App detection and clipboard code ready, needs platform testing

### Known Limitations
- ⚠️ **No cross-device sync** — Data stays on this machine (Phase 5 future feature)
- ⚠️ **No cloud backup** — Local SQLite database only
- ⚠️ **Performance at scale** — Not tested with 10,000+ items

---

## 📋 Project Structure

```
.
├── copyman/                    # Flutter application (main)
├── docs/                       # Documentation & guides
├── .github/                    # GitHub configuration
│   └── workflows/              # CI/CD workflows (GitHub Actions)
├── README.md                   # This file
├── CONTRIBUTING.md             # Contribution guidelines
├── DEVELOPMENT.md              # Development guide (in docs/)
├── SECURITY.md                 # Security policy
├── CHANGELOG.md                # Release history
├── LICENSE                     # MIT License
└── research/                   # Research & reference materials
```

---

## 📄 License

CopyMan is licensed under the MIT License. See [LICENSE](./LICENSE) for details.

---

## 👤 Author

**Richesh Gupta** — [GitHub](https://github.com/richeshgupta)

---

**CopyMan — Copy smarter. Paste faster.** ⚡
