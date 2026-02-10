# CopyMan Repository

Welcome to the CopyMan project repository. This repository contains the CopyMan clipboard manager and related documentation.

## 📦 What's Inside

### CopyMan — Cross-Platform Clipboard Manager
A lightweight, fast, and feature-rich clipboard manager for Linux, Windows, and macOS. Built with Flutter for a native desktop experience.

**Status:** ✅ Phase 2 Complete | **License:** MIT | **Built with:** Flutter 3.38.9

**Platform Support:**
- ✅ **Linux:** Fully functional (production-ready)
- ⚠️ **macOS:** Core features implemented, needs comprehensive testing
- 🔄 **Windows:** Code structure ready, requires platform validation

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

## 🚀 Quick Start

### For Users

```bash
cd copyman
flutter pub get
flutter build linux --release
./build/linux/x64/release/bundle/copyman
```

### For Developers

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
| **Phase 3** | ⚠️ Testing | macOS support (native clipboard APIs implemented, needs validation) |
| **Phase 4** | 🔄 Testing | Windows support (code ready, requires comprehensive testing) |
| **Phase 5** | 📋 Future | Cross-device sync (LAN P2P, E2EE), cloud backup, mobile apps |

### Current Focus
- ✅ **Linux Production** — Fully functional, 177 tests passing, ready for daily use
- ⚠️ **macOS Testing** — Image capture via osascript implemented, needs full validation
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
