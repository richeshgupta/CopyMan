import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'hotkey_config_service.dart';

class HotkeyService {
  HotKey? _hotKey;
  final VoidCallback? onPressed;

  HotkeyService({this.onPressed});

  Future<bool> register() async {
    try {
      final binding = HotkeyConfigService.instance.getBinding(AppAction.toggleWindow);
      _hotKey = _bindingToHotKey(binding);
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

  Future<bool> reregister() async {
    await unregister();
    return register();
  }

  HotKey _bindingToHotKey(HotkeyBinding binding) {
    final modifiers = <HotKeyModifier>[];
    if (binding.ctrl) modifiers.add(HotKeyModifier.control);
    if (binding.alt) modifiers.add(HotKeyModifier.alt);
    if (binding.shift) modifiers.add(HotKeyModifier.shift);

    // Map LogicalKeyboardKey to PhysicalKeyboardKey
    final physical = _logicalToPhysical(binding.key);

    return HotKey(
      key: physical,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );
  }

  PhysicalKeyboardKey _logicalToPhysical(LogicalKeyboardKey key) {
    // Map common keys
    if (key == LogicalKeyboardKey.keyA) return PhysicalKeyboardKey.keyA;
    if (key == LogicalKeyboardKey.keyB) return PhysicalKeyboardKey.keyB;
    if (key == LogicalKeyboardKey.keyC) return PhysicalKeyboardKey.keyC;
    if (key == LogicalKeyboardKey.keyD) return PhysicalKeyboardKey.keyD;
    if (key == LogicalKeyboardKey.keyE) return PhysicalKeyboardKey.keyE;
    if (key == LogicalKeyboardKey.keyF) return PhysicalKeyboardKey.keyF;
    if (key == LogicalKeyboardKey.keyG) return PhysicalKeyboardKey.keyG;
    if (key == LogicalKeyboardKey.keyH) return PhysicalKeyboardKey.keyH;
    if (key == LogicalKeyboardKey.keyI) return PhysicalKeyboardKey.keyI;
    if (key == LogicalKeyboardKey.keyJ) return PhysicalKeyboardKey.keyJ;
    if (key == LogicalKeyboardKey.keyK) return PhysicalKeyboardKey.keyK;
    if (key == LogicalKeyboardKey.keyL) return PhysicalKeyboardKey.keyL;
    if (key == LogicalKeyboardKey.keyM) return PhysicalKeyboardKey.keyM;
    if (key == LogicalKeyboardKey.keyN) return PhysicalKeyboardKey.keyN;
    if (key == LogicalKeyboardKey.keyO) return PhysicalKeyboardKey.keyO;
    if (key == LogicalKeyboardKey.keyP) return PhysicalKeyboardKey.keyP;
    if (key == LogicalKeyboardKey.keyQ) return PhysicalKeyboardKey.keyQ;
    if (key == LogicalKeyboardKey.keyR) return PhysicalKeyboardKey.keyR;
    if (key == LogicalKeyboardKey.keyS) return PhysicalKeyboardKey.keyS;
    if (key == LogicalKeyboardKey.keyT) return PhysicalKeyboardKey.keyT;
    if (key == LogicalKeyboardKey.keyU) return PhysicalKeyboardKey.keyU;
    if (key == LogicalKeyboardKey.keyV) return PhysicalKeyboardKey.keyV;
    if (key == LogicalKeyboardKey.keyW) return PhysicalKeyboardKey.keyW;
    if (key == LogicalKeyboardKey.keyX) return PhysicalKeyboardKey.keyX;
    if (key == LogicalKeyboardKey.keyY) return PhysicalKeyboardKey.keyY;
    if (key == LogicalKeyboardKey.keyZ) return PhysicalKeyboardKey.keyZ;
    if (key == LogicalKeyboardKey.space) return PhysicalKeyboardKey.space;
    if (key == LogicalKeyboardKey.enter) return PhysicalKeyboardKey.enter;
    if (key == LogicalKeyboardKey.escape) return PhysicalKeyboardKey.escape;
    if (key == LogicalKeyboardKey.comma) return PhysicalKeyboardKey.comma;
    // Default fallback
    return PhysicalKeyboardKey.keyV;
  }

  void dispose() {
    unregister();
  }
}
