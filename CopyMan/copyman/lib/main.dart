import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'app.dart';
import 'services/storage_service.dart';
import 'services/hotkey_config_service.dart';
import 'services/tray_service.dart';

late TrayService _trayService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── SQLite FFI bootstrap (required on desktop) ───────────────
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await StorageService.instance.init();
  await HotkeyConfigService.instance.init();

  // ── window manager ────────────────────────────────────────────
  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll();

  windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(380, 480),
      center: true,
      skipTaskbar: true,
      alwaysOnTop: true,
    ),
    () async {
      // Don't show on startup — wait for hotkey (Ctrl+Alt+V)
      await windowManager.hide();
    },
  );

  // Initialize tray service
  _trayService = TrayService(
    onShow: () {
      // Callback from tray — trigger window show through HomeScreen
    },
    onExit: () => exit(0),
  );
  await _trayService.init();

  runApp(const CopyManApp());
}
