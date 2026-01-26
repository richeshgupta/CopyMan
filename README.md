# CopyMan

Fast, cross-platform clipboard manager with unlimited history and powerful search.

## Features

- **Lightning fast** - <50ms startup, <20ms search
- **Unlimited history** - Never lose copied content
- **Powerful search** - Full-text search with instant results
- **Keyboard shortcuts** - Ctrl+Shift+V to show, vim-style navigation
- **Always available** - Runs in background, minimal resource usage
- **Cross-platform** - Linux, macOS, Windows

## Installation

### Linux
```bash
sudo dpkg -i copyman_0.1.0_amd64.deb
# or
sudo rpm -i copyman-0.1.0.x86_64.rpm
```

### macOS
```bash
# Download copyman_0.1.0_x64.dmg
# Drag to Applications folder
```

### Windows
```bash
# Run copyman_0.1.0_x64.msi
```

## Usage

### Global Shortcuts

- `Ctrl+Shift+V` - Show/hide CopyMan window
- `Ctrl+Shift+X` - Clear all history

### Keyboard Navigation

- `↑/↓` or `k/j` - Navigate list
- `Enter` - Copy selected item
- `Esc` - Clear search
- Type to search in real-time

## Architecture

- **Backend:** Rust with Tauri 2.0
- **Database:** SQLite with FTS5 full-text search
- **Search:** Hybrid (Trie + LRU cache + FTS5)
- **Frontend:** Svelte + Tailwind CSS
- **Performance:** <30MB memory, <50ms startup

## Development

### Prerequisites

#### System Dependencies (Linux)

Before building CopyMan on Linux, install the required system dependencies:

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y \
  libgtk-3-dev \
  libwebkit2gtk-4.1-dev \
  libayatana-appindicator3-dev \
  librsvg2-dev \
  patchelf \
  libjavascriptcoregtk-4.1-dev \
  libsoup-3.0-dev
```

**Fedora:**
```bash
sudo dnf install \
  gtk3-devel \
  webkit2gtk4.1-devel \
  libappindicator-gtk3-devel \
  librsvg2-devel \
  patchelf \
  openssl-devel
```

**Arch Linux:**
```bash
sudo pacman -S \
  webkit2gtk-4.1 \
  gtk3 \
  libappindicator-gtk3 \
  librsvg \
  patchelf
```

#### Rust

Install Rust if you haven't already:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

Verify installation:
```bash
rustc --version
cargo --version
```

#### Node.js

Install Node.js (v18 or later):
```bash
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18

# Or download from https://nodejs.org/
```

### Building from Source

1. **Clone the repository:**
```bash
git clone https://github.com/yourusername/copyman.git
cd copyman
```

2. **Install Node dependencies:**
```bash
npm install
```

3. **Build the frontend:**
```bash
npm run build
```

4. **Run in development mode:**
```bash
npm run tauri dev
```

This will:
- Start the Vite development server
- Compile the Rust backend
- Launch the CopyMan window
- Enable hot-reload for frontend changes

5. **Build for production:**
```bash
npm run tauri build
```

Production builds will be created in `src-tauri/target/release/bundle/`:
- **Debian/Ubuntu:** `copyman_0.1.0_amd64.deb`
- **AppImage:** `copyman_0.1.0_amd64.AppImage`
- **RPM (if rpmbuild installed):** `copyman-0.1.0-1.x86_64.rpm`

### Running Tests

**Rust backend tests:**
```bash
cd src-tauri
cargo test
```

**Frontend type checking:**
```bash
npm run check
```

### Development Tips

- **Hot reload:** Frontend changes auto-reload in dev mode
- **Rust changes:** Require app restart (Ctrl+C and `npm run tauri dev` again)
- **Database location:** `~/.local/share/com.copyman.app/clipboard.db`
- **Logs:** Check terminal output for debugging

### Common Issues

**Issue:** `cargo: command not found`
- **Solution:** Ensure Rust is installed and `$HOME/.cargo/bin` is in your PATH

**Issue:** `pkg-config: command not found`
- **Solution:** Install build tools: `sudo apt-get install pkg-config build-essential`

**Issue:** Window doesn't appear
- **Solution:** Check if running on X11/Wayland, ensure display is set: `echo $DISPLAY`

**Issue:** Global hotkeys not working
- **Solution:** Hotkeys require X11. On Wayland, they may not work depending on compositor.

## Technical Details

### Database Layer
- SQLite with FTS5 virtual tables for full-text search
- Triggers to keep FTS5 index synchronized
- Indexed timestamp for fast recent queries

### Search System
- **Trie Index**: In-memory prefix search for recent items (LRU cache)
- **FTS5 Fallback**: Full-text search across all history
- **Hybrid Strategy**: Fast recent results + comprehensive historical results

### Performance Optimizations
- Virtual scrolling for 10,000+ items
- Debounced search input (300ms)
- Background clipboard monitoring (500ms polling)
- Lazy loading and efficient rendering

## License

MIT
