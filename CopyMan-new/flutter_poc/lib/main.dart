import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'app.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── SQLite FFI bootstrap (required on desktop) ───────────────
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await StorageService.instance.init();

  // ── window manager ────────────────────────────────────────────
  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll();

  windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(420, 580),
      center: true,
      skipTaskbar: true,
      alwaysOnTop: true,
    ),
    () async {
      // Don't show on startup — wait for hotkey (Ctrl+Alt+V)
      await windowManager.hide();
    },
  );

  runApp(const CopyManApp());
}
