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

```bash
# Install dependencies
npm install

# Run in development
npm run tauri dev

# Build for production
npm run tauri build
```

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
