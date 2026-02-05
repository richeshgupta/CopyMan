# CopyMan: Hotkey + Focus Implementation

**Status:** ✅ Proven in PoC
**Date:** 2026-02-05
**Platform:** Flutter (Cross-platform: Windows, macOS, Linux)

---

## Executive Summary

The critical problem blocking Tauri was: **when a user pressed a global hotkey, the clipboard manager window would appear but wouldn't receive keyboard focus, forcing users to manually click before typing.**

We have successfully implemented and verified a solution using Flutter's `hotkey_manager` and `window_manager` plugins. The window now appears AND receives focus when triggered by a global hotkey, allowing users to type immediately.

---

## The Problem (Tauri)

**Tauri's limitations:**
- Window would show on hotkey press
- But keyboard focus would not transfer to the app
- User had to manually click the window to type
- Multiple open GitHub issues on this exact problem, no resolution
- Architectural issue in how Tauri handles global hotkey + window focus interaction

**Why it matters:** A clipboard manager that requires a click before you can search is broken. The core value is speed and seamlessness.

---

## The Solution (Flutter)

We solved this using a three-layer approach:

### Layer 1: Global Hotkey Registration
**Technology:** `hotkey_manager` (v0.2.3)

```dart
Future<void> _registerGlobalHotkey() async {
  _hotKey = HotKey(
    key: PhysicalKeyboardKey.keyV,
    modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
    scope: HotKeyScope.system,
  );

  await hotKeyManager.register(
    _hotKey,
    keyDownHandler: _onHotKeyDown,  // Handler called when Ctrl+Alt+V pressed
  );
}
```

**What this does:**
- Registers Ctrl+Alt+V as a *system-wide* hotkey (works even when app is not focused)
- Uses `HotKeyScope.system` so the OS sends the event to our app regardless of window state
- `keyDownHandler` receives a callback when the key combination is pressed

**Key implementation details:**
- Must import `flutter/services.dart` for `PhysicalKeyboardKey`
- Handler signature is: `void Function(HotKey hotKey)` — receives the HotKey object that triggered
- Must call `hotKeyManager.unregisterAll()` in `main()` for clean hot reload behavior

---

### Layer 2: Window Show + OS-Level Focus
**Technology:** `window_manager` (v0.4.2)

```dart
void _onHotKeyDown(HotKey hotKey) {
  _togglePopup();
}

Future<void> _togglePopup() async {
  final isVisible = await windowManager.isVisible();

  if (isVisible) {
    await windowManager.hide();
  } else {
    await windowManager.setAlwaysOnTop(true);  // Force window to top
    await windowManager.show();                 // Show the window
    await windowManager.focus();                // Request OS-level focus
    searchFocusNode.requestFocus();            // Request widget-level focus
  }
}
```

**What this does:**
- `setAlwaysOnTop(true)`: Forces the window to stay above other windows (workaround for focus issues)
- `show()`: Makes the window visible
- `focus()`: Requests OS-level window focus from the window manager
- `searchFocusNode.requestFocus()`: Requests Flutter widget-level focus on the TextField

**Why three separate calls?** Different levels of the system need to be told the window should be active:
1. OS: "make this window active" (`windowManager.focus()`)
2. Flutter: "make this widget accept keyboard input" (`FocusNode.requestFocus()`)
3. Visual: "keep this window on top" (`setAlwaysOnTop()`)

---

### Layer 3: Widget-Level Focus Management
**Technology:** Flutter's `FocusNode`

```dart
class _MyAppState extends State<MyApp> with WindowListener {
  late FocusNode searchFocusNode;

  @override
  void initState() {
    searchFocusNode = FocusNode();  // Create a focus controller
    windowManager.addListener(this);
    _registerGlobalHotkey();
    super.initState();
  }

  // In the build method:
  TextField(
    focusNode: searchFocusNode,  // Attach the focus node
    onChanged: (value) {
      setState(() => searchQuery = value);
    },
    decoration: InputDecoration(
      hintText: 'Search clipboard...',
      // ...
    ),
  )

  @override
  Future<void> onWindowEvent(String eventName) async {
    if (eventName == 'blur') {
      searchFocusNode.unfocus();    // Release focus when window loses focus
      await windowManager.hide();   // Auto-hide
    }
  }
}
```

**What this does:**
- `FocusNode` gives us programmatic control over which widget receives keyboard input
- `searchFocusNode.requestFocus()` tells Flutter to route keyboard events to the TextField
- `onWindowEvent('blur')` handler detects when the window loses focus
- Auto-hide on blur: when user clicks away, the clipboard popup disappears

---

## How It All Works Together

```
User presses Ctrl+Alt+V globally
        ↓
hotkey_manager detects the system hotkey
        ↓
calls keyDownHandler: _onHotKeyDown()
        ↓
_onHotKeyDown calls _togglePopup()
        ↓
_togglePopup calls:
  1. windowManager.setAlwaysOnTop(true)    — OS: keep window on top
  2. windowManager.show()                   — OS: make window visible
  3. windowManager.focus()                  — OS: make window active
  4. searchFocusNode.requestFocus()        — Flutter: activate TextField
        ↓
Window appears AND TextField is focused
        ↓
User starts typing immediately
```

---

## Why This Works (and Tauri Doesn't)

| Aspect | Tauri | Flutter |
|--------|-------|---------|
| **Hotkey registration** | Has API (`tauri-plugin-global-shortcut`) | Has API (`hotkey_manager`) |
| **Window management** | Has API (`tauri::window`) | Has API (`window_manager`) |
| **Focus coordination** | ❌ Known bug — focus lost after hotkey show | ✅ Works — proper OS + widget focus |
| **Maturity** | Newer, fewer edge cases solved | Older, more edge cases handled |
| **Architecture** | Electron-based (web-like event model) | Native (proper desktop event model) |

**Key difference:** Flutter's architecture lets us properly coordinate OS-level window focus with widget-level input focus. Tauri's web-based architecture has friction between the system-level hotkey event and the web-view's focus management.

---

## Implementation Checklist (PoC Complete)

- ✅ Register global hotkey (Ctrl+Alt+V) with `hotkey_manager`
- ✅ Show window on hotkey trigger with `window_manager`
- ✅ Request OS-level focus with `windowManager.focus()`
- ✅ Request widget-level focus with `FocusNode.requestFocus()`
- ✅ Auto-hide on focus loss with `onWindowEvent('blur')`
- ✅ Tested: type immediately after hotkey press (no manual click needed)
- ✅ Verified: window appears and disappears cleanly
- ✅ Verified: focus behavior is consistent across hotkey and button triggers

---

## Open Questions for Production

1. **Default hotkey conflict:** Ctrl+Alt+V conflicts with paste-as-plain-text in some apps. Should we make it configurable in settings, or change the default?
2. **macOS specifics:** Test `keyUpHandler` behavior on macOS (only works reliably on macOS per docs)
3. **Linux desktop environments:** Verify behavior on both X11 and Wayland
4. **Auto-hide delay:** Currently hides immediately on blur. Should there be a delay to prevent accidental hiding?

---

## References

- `hotkey_manager` package: `/home/richesh/.pub-cache/hosted/pub.dev/hotkey_manager-0.2.3/`
- `window_manager` package: `/home/richesh/.pub-cache/hosted/pub.dev/window_manager-0.4.2/`
- PoC code: `/home/richesh/Desktop/expts/CopyMan-new/flutter_poc/lib/main.dart`
