# CopyMan Repository

Welcome to the CopyMan project repository. This repository contains the CopyMan clipboard manager and related documentation.

## 📦 What's Inside

### CopyMan — Cross-Platform Clipboard Manager
A lightweight, fast, and feature-rich clipboard manager for Linux, Windows, and macOS. Built with Flutter for a native desktop experience.

**Status:** ✅ Phase 2 Complete | **License:** MIT | **Built with:** Flutter 3.38.9

⚠️ **Current Platform Support:** Linux only. macOS and Windows support coming soon.

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

## 📥 Installation

### Pre-built Binary (Recommended) — Linux

The easiest way to get started! Download and run in 3 steps.

#### Step 1: Download Latest Release

```bash
# Download the latest release
wget https://github.com/richeshgupta/CopyMan/releases/latest/download/copyman-0.1.0-linux-x64.tar.gz

# (Optional) Verify checksum for security
wget https://github.com/richeshgupta/CopyMan/releases/latest/download/copyman-0.1.0-linux-x64.tar.gz.sha256
sha256sum -c copyman-0.1.0-linux-x64.tar.gz.sha256
```

#### Step 2: Extract the Archive

```bash
tar xzf copyman-0.1.0-linux-x64.tar.gz
cd copyman-0.1.0-linux-x64
```

#### Step 3: Install

```bash
./install.sh
```

The installer will place CopyMan in `~/.local/` (no sudo required).

#### Step 4: Run CopyMan

```bash
copyman
```

Or find **CopyMan** in your applications menu (may require logout/login for app launcher to refresh).

#### System Requirements

**OS:** Linux x86_64 (Ubuntu 20.04+, Fedora 35+, Arch, or equivalent)

**Libraries:** Most Linux desktop systems have these pre-installed. If CopyMan won't start, install:

```bash
# Debian/Ubuntu
sudo apt-get install libgtk-3-0 libsqlite3-0

# Fedora/RHEL
sudo dnf install gtk3 sqlite

# Arch Linux
sudo pacman -S gtk3 sqlite
```

#### Uninstall

```bash
~/.local/share/copyman/uninstall.sh
```

---

## 🚀 Quick Start (Build from Source)

### For Developers

If you prefer to build from source:

```bash
cd copyman
flutter pub get
flutter build linux --release
./build/linux/x64/release/bundle/copyman
```

Or use `flutter run` for development:

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
| **Phase 2** | ✅ Complete | Keyboard-first UI, configurable shortcuts, groups, sequential paste |
| **Phase 3** | 📋 Planned | macOS support (native clipboard APIs, system integration) |
| **Phase 4** | 📋 Planned | Windows support (Win32 APIs, system integration) |
| **Phase 5** | 📋 Future | Cross-device sync (LAN P2P, E2EE), cloud backup, mobile apps |

### Current Focus
- ✅ **Linux MVP** — Fully functional, keyboard-first, ready for daily use
- 🔄 **macOS Expansion** — Native APIs for clipboard/hotkey/window management
- 🔄 **Windows Expansion** — Win32 integration for seamless experience

### Known Limitations (Linux v2.0)
- ⚠️ **Image capture not implemented** — Text-only clipboard history
- ⚠️ **No cross-device sync** — Data stays on this machine
- ⚠️ **No cloud backup** — Local SQLite database only

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
