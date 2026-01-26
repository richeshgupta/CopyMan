# CopyMan Testing Guide

This document describes all test cases for CopyMan's window behavior, focus handling, settings, and clipboard selection.

## Running Tests

### Frontend Tests (Vitest)

```bash
# Install dependencies first
npm install

# Run all tests
npm test

# Run tests with UI
npm run test:ui

# Run tests with coverage
npm run test:coverage

# Run specific test file
npx vitest run src/test/window-behavior.test.ts
```

### Backend Tests (Rust)

```bash
cd src-tauri
cargo test

# Run with output
cargo test -- --nocapture

# Run specific test
cargo test test_settings_structure
```

## Test Coverage

### 1. Window Visibility Behavior (`window-behavior.test.ts`)

Tests all scenarios for when the window should appear and disappear.

**Window APPEAR Tests:**
- ✅ Show window and focus input on tray icon click (when hidden)
- ✅ Hide window on tray icon click (when visible)
- ✅ Show window on "Show/Hide CopyMan" menu (when hidden)
- ✅ Hide window on "Show/Hide CopyMan" menu (when visible)
- ✅ Show window and open Settings on "Settings" menu (when hidden)
- ✅ Keep visible and open Settings on "Settings" menu (when visible)
- ✅ Show window and focus on global hotkey (when hidden)

**Window DISAPPEAR Tests:**
- ✅ Hide immediately after selecting item with number key (1-9)
- ✅ Hide immediately after selecting item with Enter key
- ✅ Hide immediately after clicking an item
- ✅ Hide on blur (click outside) when Settings NOT open
- ✅ Hide on blur (click outside) when Settings IS open
- ✅ NOT hide on blur when dialog is open
- ✅ Hide window when clicking close button (×)
- ✅ Hide window on Escape key (when Settings NOT open)

**Window STAY VISIBLE Tests:**
- ✅ Stay visible when confirmation dialog is active
- ✅ Stay visible when typing in search box
- ✅ Stay visible when navigating with j/k/arrows

**Race Condition Tests:**
- ✅ Prevent hiding twice when blur and selection happen simultaneously
- ✅ Reset isHiding flag after hide completes

### 2. Focus Behavior (`focus-behavior.test.ts`)

Tests keyboard focus handling for all scenarios.

**Search Input Focus Tests:**
- ✅ Focus search input when window opens (clipboard view)
- ✅ Focus search input on first open
- ✅ Focus search input on consecutive opens
- ✅ Attempt focus multiple times to handle timing issues
- ✅ Focus search input after closing Settings
- ✅ Focus search input after dialog closes
- ✅ Refocus search input after clearing with Escape

**Settings Focus Tests:**
- ✅ NOT focus search input when Settings opens
- ✅ Focus first input in Settings modal when Settings opens

**Focus Persistence Tests:**
- ✅ Maintain focus on search input during typing
- ✅ Maintain focus during keyboard navigation (j/k)

**Window Manager Tests:**
- ✅ Request window manager attention on Linux
- ✅ Call setFocus immediately after showing window
- ✅ Call setFocus multiple times with delays

**Focus State Tests:**
- ✅ Reset isHiding flag when window gains focus

### 3. Settings Modal Behavior (`settings-behavior.test.ts`)

Tests Settings modal opening, closing, and interaction.

**Opening Settings Tests:**
- ✅ Open Settings when clicking "Settings" from tray menu
- ✅ Show window first if hidden, then open Settings
- ✅ Open Settings without hiding window if already visible
- ✅ Open Settings with Ctrl+K keyboard shortcut

**Closing Settings Tests:**
- ✅ Close Settings when clicking Cancel button
- ✅ Close Settings when clicking close button (×)
- ✅ Close Settings when pressing Escape key
- ✅ Close Settings when clicking outside modal but inside window
- ✅ NOT close Settings when clicking inside modal
- ✅ Close Settings AND hide window when clicking outside window

**Settings Persistence Tests:**
- ✅ Load settings on Settings modal mount
- ✅ Save settings when clicking Save button
- ✅ Show success message after saving settings
- ✅ Show error message if save fails
- ✅ Clear success message after 3 seconds

**Settings State Management Tests:**
- ✅ NOT hide window on blur when Settings is open
- ✅ Reset showSettings to false when window is shown next time
- ✅ NOT reset showSettings if Settings menu was clicked

**Settings Validation Tests:**
- ✅ Disable Save button while saving
- ✅ Handle empty settings gracefully

### 4. Clipboard Selection (`clipboard-selection.test.ts`)

Tests clipboard item selection and window hiding.

**Number Key Selection Tests (1-9, 0):**
- ✅ Select first item with key "1"
- ✅ Select second item with key "2"
- ✅ Select 10th item with key "0"
- ✅ NOT select if number exceeds available entries
- ✅ Hide window immediately after number key selection (no delay)

**Enter Key Selection Tests:**
- ✅ Select currently highlighted item with Enter
- ✅ Hide window immediately after Enter selection (no delay)

**Mouse Click Selection Tests:**
- ✅ Select item when clicked
- ✅ Hide window immediately after click selection (no delay)

**Navigation Keys Tests (j/k, arrows):**
- ✅ Move selection down with "j" key
- ✅ Move selection down with ArrowDown
- ✅ Move selection up with "k" key
- ✅ Move selection up with ArrowUp
- ✅ NOT move selection below 0
- ✅ NOT move selection above max index
- ✅ NOT hide window while navigating

**Copy to Clipboard Tests:**
- ✅ Copy selected entry content to clipboard
- ✅ Handle copy errors gracefully

**Race Condition Tests:**
- ✅ Not hide twice when selection and blur happen simultaneously

**Search and Selection Tests:**
- ✅ Be able to select filtered items

### 5. Dialog Behavior (`dialog-behavior.test.ts`)

Tests confirmation dialog handling (Clear History).

**Clear History Dialog Tests:**
- ✅ Show confirmation dialog when "Clear History" clicked
- ✅ Clear history if user confirms
- ✅ NOT clear history if user cancels
- ✅ NOT hide window when dialog is open
- ✅ Set isDialogOpen flag before showing dialog
- ✅ Reset isDialogOpen flag after dialog closes
- ✅ Stay visible after user confirms and history clears
- ✅ Stay visible after user cancels

**Dialog Window Interaction Tests:**
- ✅ Prevent blur handler from hiding during dialog
- ✅ Allow blur handler to work after dialog closes
- ✅ Focus search input after dialog closes

**Dialog Timing Tests:**
- ✅ Set flag immediately before dialog shows
- ✅ Reset flag immediately after dialog closes

**Multiple Dialog Prevention Tests:**
- ✅ Not show multiple dialogs simultaneously

**Dialog Error Handling Tests:**
- ✅ Handle errors during clear operation
- ✅ Reset dialog flag even if error occurs

### 6. Rust Backend Tests

Located in `src-tauri/src/commands/mod.rs`.

**Settings Structure Tests:**
- ✅ Settings structure with default hotkeys
- ✅ Settings with empty hotkeys
- ✅ Settings serialization to JSON

## Test Statistics

- **Total Test Files:** 6
- **Total Test Cases:** 100+
- **Frontend Tests:** 90+
- **Backend Tests:** 3+

## Coverage Goals

- **Window Behavior:** 100% of specification table
- **Focus Handling:** All focus scenarios
- **Settings Modal:** All interaction paths
- **Clipboard Selection:** All selection methods
- **Dialog Handling:** All dialog states
- **Race Conditions:** All concurrent operations

## Continuous Integration

To add these tests to CI:

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install
      - run: npm test

  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions-rs/toolchain@v1
        with:
          toolchain: stable
      - run: cd src-tauri && cargo test
```

## Manual Testing Checklist

In addition to automated tests, perform these manual tests:

### Focus Tests
- [ ] Window appears and search is focused on first open
- [ ] Window appears and search is focused on second+ opens
- [ ] Can immediately press 1-9 to select without clicking
- [ ] Focus works after selecting an item and reopening

### Window Behavior Tests
- [ ] Clicking outside closes window
- [ ] Clicking outside with Settings open closes both
- [ ] Clicking outside with dialog open does NOT close
- [ ] Window closes immediately after selection (no delay)

### Settings Tests
- [ ] Settings opens from tray menu
- [ ] Settings persists changes
- [ ] Clicking outside Settings modal closes it
- [ ] Escape closes Settings without saving

### Dialog Tests
- [ ] Clear History shows confirmation
- [ ] Window stays visible during confirmation
- [ ] Can cancel confirmation
- [ ] Clicking outside doesn't close during dialog

## Known Limitations

1. **Tauri API Mocking:** Some Tauri-specific behaviors are difficult to fully test in unit tests and require integration/E2E tests.

2. **Window Manager Interactions:** Platform-specific window manager behavior (especially on Linux) may vary and require manual testing.

3. **Timing-Dependent Tests:** Some tests involve delays and timing, which may be flaky in slow environments.

## Future Improvements

- [ ] Add E2E tests using Playwright or similar
- [ ] Add visual regression tests
- [ ] Add performance benchmarks
- [ ] Add tests for keyboard shortcuts (global hotkeys)
- [ ] Add tests for tray icon interactions
- [ ] Add tests for database operations
