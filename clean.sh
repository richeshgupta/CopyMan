#!/bin/bash

echo "🧹 Cleaning CopyMan caches..."

# Clean Rust/Cargo cache
echo "📦 Cleaning Rust build artifacts..."
cd src-tauri
cargo clean
cd ..

# Clean npm cache and node_modules
echo "📦 Cleaning npm cache..."
rm -rf node_modules
rm -rf node_modules/.vite
rm -rf dist

# Clean Tauri build artifacts
echo "📦 Cleaning Tauri artifacts..."
rm -rf src-tauri/target

# Clean npm cache (global)
echo "📦 Cleaning npm global cache..."
npm cache clean --force

# Clean lock files (optional - uncomment if needed)
# rm -f package-lock.json
# rm -f src-tauri/Cargo.lock

echo "✅ All caches cleaned!"
echo ""
echo "To rebuild:"
echo "  npm install"
echo "  npm run tauri dev"
