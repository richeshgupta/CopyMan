#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ─── Kill existing process ─────────────────────────────────────────
if pgrep -f "copyman" > /dev/null; then
  echo -e "${YELLOW}⊘ Killing existing CopyMan process...${NC}"
  pkill -f "copyman" || true
  sleep 1
fi

# ─── Build ────────────────────────────────────────────────────────
echo -e "${YELLOW}🔨 Building CopyMan...${NC}"
CC=$HOME/bin/clang \
CXX=$HOME/bin/clang++ \
LD=$HOME/bin/ld \
PATH=$HOME/bin:$PATH \
/home/richesh/flutter/bin/flutter build linux --release

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Build failed${NC}"
  exit 1
fi

# ─── Run ───────────────────────────────────────────────────────────
echo -e "${GREEN}✓ Build successful${NC}"
echo -e "${YELLOW}🚀 Launching CopyMan...${NC}"

./build/linux/x64/release/bundle/copyman &
PID=$!

sleep 2
if ps -p $PID > /dev/null; then
  echo -e "${GREEN}✓ CopyMan running (PID: $PID)${NC}"
  echo ""
  echo -e "${GREEN}Keyboard shortcuts:${NC}"
  echo "  Ctrl+Alt+V  Toggle window (global hotkey)"
  echo "  Space       Toggle preview overlay"
  echo "  Enter       Copy selected"
  echo "  Ctrl+Enter  Copy & Paste"
  echo "  Ctrl+P      Toggle pin"
  echo "  Delete      Delete item"
  echo "  Ctrl+,      Open Settings"
  echo "  Escape      Close window"
  echo ""
else
  echo -e "${RED}✗ Failed to launch CopyMan${NC}"
  exit 1
fi
