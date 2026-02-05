import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyService {
  HotKey? _hotKey;
  final VoidCallback? onPressed;

  HotkeyService({this.onPressed});

  Future<bool> register() async {
    try {
      _hotKey = HotKey(
        key: PhysicalKeyboardKey.keyV,
        modifiers: [HotKeyModifier.control, HotKeyModifier.alt],
        scope: HotKeyScope.system,
      );
      await hotKeyManager.register(
        _hotKey!,
        keyDownHandler: (_) => onPressed?.call(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> unregister() async {
    if (_hotKey != null) {
      await hotKeyManager.unregister(_hotKey!);
      _hotKey = null;
    }
  }

  void dispose() {
    unregister();
  }
}
