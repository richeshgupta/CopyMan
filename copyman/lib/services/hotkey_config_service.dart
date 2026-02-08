import 'dart:io';

import 'package:flutter/services.dart';

import 'storage_service.dart';

enum AppAction {
  toggleWindow,
  copy,
  copyAndPaste,
  pastePlain,
  deleteItem,
  togglePin,
  selectAll,
  startSequence,
  togglePreview,
  moveUp,
  moveDown,
  close,
  openSettings,
}

class HotkeyBinding {
  final LogicalKeyboardKey key;
  final bool ctrl;
  final bool shift;
  final bool alt;

  const HotkeyBinding({
    required this.key,
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
  });

  bool matches(KeyEvent event) {
    if (event.logicalKey != key) return false;
    final hw = HardwareKeyboard.instance;
    if (ctrl != hw.isControlPressed) return false;
    if (shift != hw.isShiftPressed) return false;
    if (alt != hw.isAltPressed) return false;
    return true;
  }

  String describe() {
    final parts = <String>[];
    if (ctrl) parts.add(Platform.isMacOS ? '⌘' : 'Ctrl');
    if (alt) parts.add(Platform.isMacOS ? '⌥' : 'Alt');
    if (shift) parts.add(Platform.isMacOS ? '⇧' : 'Shift');
    parts.add(_keyLabel(key));
    return parts.join(Platform.isMacOS ? '' : '+');
  }

  @override
  String toString() {
    final parts = <String>[];
    if (ctrl) parts.add('ctrl');
    if (alt) parts.add('alt');
    if (shift) parts.add('shift');
    parts.add(_keyToString(key));
    return parts.join('+');
  }

  static HotkeyBinding parse(String str) {
    final parts = str.toLowerCase().split('+');
    bool ctrl = false, shift = false, alt = false;
    String keyPart = parts.last;

    for (final p in parts) {
      if (p == 'ctrl') {
        ctrl = true;
      } else if (p == 'shift') {
        shift = true;
      } else if (p == 'alt') {
        alt = true;
      } else {
        keyPart = p;
      }
    }

    return HotkeyBinding(
      key: _stringToKey(keyPart),
      ctrl: ctrl,
      shift: shift,
      alt: alt,
    );
  }

  static String _keyToString(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.enter) return 'enter';
    if (key == LogicalKeyboardKey.escape) return 'escape';
    if (key == LogicalKeyboardKey.space) return 'space';
    if (key == LogicalKeyboardKey.delete) return 'delete';
    if (key == LogicalKeyboardKey.backspace) return 'backspace';
    if (key == LogicalKeyboardKey.arrowUp) return 'arrow_up';
    if (key == LogicalKeyboardKey.arrowDown) return 'arrow_down';
    if (key == LogicalKeyboardKey.arrowLeft) return 'arrow_left';
    if (key == LogicalKeyboardKey.arrowRight) return 'arrow_right';
    if (key == LogicalKeyboardKey.tab) return 'tab';
    if (key == LogicalKeyboardKey.comma) return 'comma';
    // Letter keys
    final label = key.keyLabel.toLowerCase();
    if (label.isNotEmpty) return label;
    return key.keyId.toString();
  }

  static LogicalKeyboardKey _stringToKey(String s) {
    switch (s) {
      case 'enter': return LogicalKeyboardKey.enter;
      case 'escape': return LogicalKeyboardKey.escape;
      case 'space': return LogicalKeyboardKey.space;
      case 'delete': return LogicalKeyboardKey.delete;
      case 'backspace': return LogicalKeyboardKey.backspace;
      case 'arrow_up': return LogicalKeyboardKey.arrowUp;
      case 'arrow_down': return LogicalKeyboardKey.arrowDown;
      case 'arrow_left': return LogicalKeyboardKey.arrowLeft;
      case 'arrow_right': return LogicalKeyboardKey.arrowRight;
      case 'tab': return LogicalKeyboardKey.tab;
      case 'comma': return LogicalKeyboardKey.comma;
      case 'a': return LogicalKeyboardKey.keyA;
      case 'b': return LogicalKeyboardKey.keyB;
      case 'c': return LogicalKeyboardKey.keyC;
      case 'd': return LogicalKeyboardKey.keyD;
      case 'e': return LogicalKeyboardKey.keyE;
      case 'f': return LogicalKeyboardKey.keyF;
      case 'g': return LogicalKeyboardKey.keyG;
      case 'h': return LogicalKeyboardKey.keyH;
      case 'i': return LogicalKeyboardKey.keyI;
      case 'j': return LogicalKeyboardKey.keyJ;
      case 'k': return LogicalKeyboardKey.keyK;
      case 'l': return LogicalKeyboardKey.keyL;
      case 'm': return LogicalKeyboardKey.keyM;
      case 'n': return LogicalKeyboardKey.keyN;
      case 'o': return LogicalKeyboardKey.keyO;
      case 'p': return LogicalKeyboardKey.keyP;
      case 'q': return LogicalKeyboardKey.keyQ;
      case 'r': return LogicalKeyboardKey.keyR;
      case 's': return LogicalKeyboardKey.keyS;
      case 't': return LogicalKeyboardKey.keyT;
      case 'u': return LogicalKeyboardKey.keyU;
      case 'v': return LogicalKeyboardKey.keyV;
      case 'w': return LogicalKeyboardKey.keyW;
      case 'x': return LogicalKeyboardKey.keyX;
      case 'y': return LogicalKeyboardKey.keyY;
      case 'z': return LogicalKeyboardKey.keyZ;
      default: return LogicalKeyboardKey.space;
    }
  }

  static String _keyLabel(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.delete) return 'Delete';
    if (key == LogicalKeyboardKey.backspace) return 'Backspace';
    if (key == LogicalKeyboardKey.arrowUp) return '\u2191';
    if (key == LogicalKeyboardKey.arrowDown) return '\u2193';
    if (key == LogicalKeyboardKey.arrowLeft) return '\u2190';
    if (key == LogicalKeyboardKey.arrowRight) return '\u2192';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.comma) return ',';
    final label = key.keyLabel;
    if (label.isNotEmpty) return label.toUpperCase();
    return '?';
  }
}

class HotkeyConfigService {
  static final HotkeyConfigService instance = HotkeyConfigService();

  static const Map<AppAction, HotkeyBinding> _defaults = {
    AppAction.toggleWindow: HotkeyBinding(key: LogicalKeyboardKey.keyV, ctrl: true, alt: true),
    AppAction.copy: HotkeyBinding(key: LogicalKeyboardKey.enter),
    AppAction.copyAndPaste: HotkeyBinding(key: LogicalKeyboardKey.enter, ctrl: true),
    AppAction.pastePlain: HotkeyBinding(key: LogicalKeyboardKey.enter, ctrl: true, shift: true),
    AppAction.deleteItem: HotkeyBinding(key: LogicalKeyboardKey.delete),
    AppAction.togglePin: HotkeyBinding(key: LogicalKeyboardKey.keyP, ctrl: true),
    AppAction.selectAll: HotkeyBinding(key: LogicalKeyboardKey.keyA, ctrl: true),
    AppAction.startSequence: HotkeyBinding(key: LogicalKeyboardKey.keyS, ctrl: true, shift: true),
    AppAction.togglePreview: HotkeyBinding(key: LogicalKeyboardKey.space),
    AppAction.moveUp: HotkeyBinding(key: LogicalKeyboardKey.arrowUp),
    AppAction.moveDown: HotkeyBinding(key: LogicalKeyboardKey.arrowDown),
    AppAction.close: HotkeyBinding(key: LogicalKeyboardKey.escape),
    AppAction.openSettings: HotkeyBinding(key: LogicalKeyboardKey.comma, ctrl: true),
  };

  final Map<AppAction, HotkeyBinding> _bindings = {};

  Future<void> init() async {
    for (final action in AppAction.values) {
      final settingKey = 'hotkey.${action.name}';
      final stored = await StorageService.instance.getSetting(settingKey);
      if (stored != null) {
        _bindings[action] = HotkeyBinding.parse(stored);
      } else {
        _bindings[action] = _defaults[action]!;
      }
    }
  }

  bool matches(AppAction action, KeyEvent event) {
    final binding = _bindings[action] ?? _defaults[action]!;
    return binding.matches(event);
  }

  HotkeyBinding getBinding(AppAction action) {
    return _bindings[action] ?? _defaults[action]!;
  }

  String describeBinding(AppAction action) {
    return getBinding(action).describe();
  }

  Future<void> setBinding(AppAction action, HotkeyBinding binding) async {
    _bindings[action] = binding;
    final settingKey = 'hotkey.${action.name}';
    await StorageService.instance.setSetting(settingKey, binding.toString());
  }

  /// For testing only: directly set a binding without persisting to DB.
  void setBindingForTest(AppAction action, HotkeyBinding binding) {
    _bindings[action] = binding;
  }

  AppAction? findConflict(AppAction forAction, HotkeyBinding binding) {
    for (final entry in _bindings.entries) {
      if (entry.key == forAction) continue;
      final b = entry.value;
      if (b.key == binding.key && b.ctrl == binding.ctrl &&
          b.shift == binding.shift && b.alt == binding.alt) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> resetAllToDefaults() async {
    for (final action in AppAction.values) {
      _bindings[action] = _defaults[action]!;
      final settingKey = 'hotkey.${action.name}';
      await StorageService.instance.setSetting(settingKey, _defaults[action]!.toString());
    }
  }

  static String actionDisplayName(AppAction action) {
    switch (action) {
      case AppAction.toggleWindow: return 'Toggle Window';
      case AppAction.copy: return 'Copy';
      case AppAction.copyAndPaste: return 'Copy & Paste';
      case AppAction.pastePlain: return 'Paste Plain';
      case AppAction.deleteItem: return 'Delete Item';
      case AppAction.togglePin: return 'Toggle Pin';
      case AppAction.selectAll: return 'Select All';
      case AppAction.startSequence: return 'Start Sequence';
      case AppAction.togglePreview: return 'Toggle Preview';
      case AppAction.moveUp: return 'Move Up';
      case AppAction.moveDown: return 'Move Down';
      case AppAction.close: return 'Close';
      case AppAction.openSettings: return 'Open Settings';
    }
  }
}
