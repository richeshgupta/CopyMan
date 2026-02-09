import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/services/hotkey_config_service.dart';

void main() {
  group('HotkeyBinding.parse', () {
    test('parses "ctrl+alt+v"', () {
      final binding = HotkeyBinding.parse('ctrl+alt+v');
      expect(binding.key, LogicalKeyboardKey.keyV);
      expect(binding.ctrl, isTrue);
      expect(binding.alt, isTrue);
      expect(binding.shift, isFalse);
    });

    test('parses "shift+enter"', () {
      final binding = HotkeyBinding.parse('shift+enter');
      expect(binding.key, LogicalKeyboardKey.enter);
      expect(binding.shift, isTrue);
      expect(binding.ctrl, isFalse);
      expect(binding.alt, isFalse);
    });

    test('parses single key "escape"', () {
      final binding = HotkeyBinding.parse('escape');
      expect(binding.key, LogicalKeyboardKey.escape);
      expect(binding.ctrl, isFalse);
      expect(binding.shift, isFalse);
      expect(binding.alt, isFalse);
    });

    test('toString() round-trips through parse()', () {
      final bindings = [
        HotkeyBinding(key: LogicalKeyboardKey.keyV, ctrl: true, alt: true),
        HotkeyBinding(key: LogicalKeyboardKey.enter),
        HotkeyBinding(key: LogicalKeyboardKey.escape),
        HotkeyBinding(key: LogicalKeyboardKey.space),
        HotkeyBinding(key: LogicalKeyboardKey.delete),
        HotkeyBinding(key: LogicalKeyboardKey.arrowUp),
        HotkeyBinding(key: LogicalKeyboardKey.comma, ctrl: true),
      ];
      for (final b in bindings) {
        final str = b.toString();
        final parsed = HotkeyBinding.parse(str);
        expect(parsed.key, b.key, reason: 'key mismatch for $str');
        expect(parsed.ctrl, b.ctrl, reason: 'ctrl mismatch for $str');
        expect(parsed.shift, b.shift, reason: 'shift mismatch for $str');
        expect(parsed.alt, b.alt, reason: 'alt mismatch for $str');
      }
    });
  });

  group('HotkeyConfigService', () {
    late HotkeyConfigService service;

    setUp(() {
      service = HotkeyConfigService();
      // Manually populate bindings with defaults via reflection-free approach:
      // We use the public API after calling init would require StorageService.
      // Instead, test the static/pure methods directly.
    });

    test('actionDisplayName returns non-empty string for all AppAction values', () {
      for (final action in AppAction.values) {
        final name = HotkeyConfigService.actionDisplayName(action);
        expect(name, isNotEmpty, reason: '${action.name} has empty display name');
      }
    });

    test('all 13 default bindings have unique key combos', () {
      // Access defaults through toString+parse round-trip indirectly
      // by checking that the known defaults don't conflict with each other.
      // We reconstruct the defaults map here for verification.
      final defaults = <String, String>{};
      final expectedDefaults = {
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
      expect(expectedDefaults.length, 13);

      for (final entry in expectedDefaults.entries) {
        final key = entry.value.toString();
        expect(defaults.containsKey(key), isFalse,
            reason: '${entry.key.name} conflicts with ${defaults[key]}');
        defaults[key] = entry.key.name;
      }
    });

    test('findConflict returns null for unique binding', () {
      // Populate service manually with known defaults
      for (final action in AppAction.values) {
        service.setBindingForTest(action, _defaultBinding(action));
      }
      // A totally new binding should not conflict
      final novel = HotkeyBinding(key: LogicalKeyboardKey.keyZ, ctrl: true, shift: true, alt: true);
      expect(service.findConflict(AppAction.copy, novel), isNull);
    });

    test('findConflict returns conflicting action when binding is duplicate', () {
      for (final action in AppAction.values) {
        service.setBindingForTest(action, _defaultBinding(action));
      }
      // toggleWindow uses ctrl+alt+v; asking copy to use same should conflict
      final sameAsToggle = HotkeyBinding(key: LogicalKeyboardKey.keyV, ctrl: true, alt: true);
      expect(service.findConflict(AppAction.copy, sameAsToggle), AppAction.toggleWindow);
    });

    test('findConflict ignores the action being edited (no self-conflict)', () {
      for (final action in AppAction.values) {
        service.setBindingForTest(action, _defaultBinding(action));
      }
      // toggleWindow editing with its own binding should return null
      final sameAsToggle = HotkeyBinding(key: LogicalKeyboardKey.keyV, ctrl: true, alt: true);
      expect(service.findConflict(AppAction.toggleWindow, sameAsToggle), isNull);
    });
  });
}

/// Returns the known default binding for each action (mirrors the private _defaults map).
HotkeyBinding _defaultBinding(AppAction action) {
  switch (action) {
    case AppAction.toggleWindow:
      return HotkeyBinding(key: LogicalKeyboardKey.keyV, ctrl: true, alt: true);
    case AppAction.copy:
      return HotkeyBinding(key: LogicalKeyboardKey.enter);
    case AppAction.copyAndPaste:
      return HotkeyBinding(key: LogicalKeyboardKey.enter, ctrl: true);
    case AppAction.pastePlain:
      return HotkeyBinding(key: LogicalKeyboardKey.enter, ctrl: true, shift: true);
    case AppAction.deleteItem:
      return HotkeyBinding(key: LogicalKeyboardKey.delete);
    case AppAction.togglePin:
      return HotkeyBinding(key: LogicalKeyboardKey.keyP, ctrl: true);
    case AppAction.selectAll:
      return HotkeyBinding(key: LogicalKeyboardKey.keyA, ctrl: true);
    case AppAction.startSequence:
      return HotkeyBinding(key: LogicalKeyboardKey.keyS, ctrl: true, shift: true);
    case AppAction.togglePreview:
      return HotkeyBinding(key: LogicalKeyboardKey.space);
    case AppAction.moveUp:
      return HotkeyBinding(key: LogicalKeyboardKey.arrowUp);
    case AppAction.moveDown:
      return HotkeyBinding(key: LogicalKeyboardKey.arrowDown);
    case AppAction.close:
      return HotkeyBinding(key: LogicalKeyboardKey.escape);
    case AppAction.openSettings:
      return HotkeyBinding(key: LogicalKeyboardKey.comma, ctrl: true);
  }
}
