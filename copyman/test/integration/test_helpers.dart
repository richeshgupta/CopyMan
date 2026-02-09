import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:copyman/models/clipboard_item.dart';
import 'package:copyman/screens/settings_screen.dart';
import 'package:copyman/services/hotkey_config_service.dart';
import 'package:copyman/services/storage_service.dart';
import 'package:copyman/theme/app_theme.dart';

/// Initialize in-memory SQLite + hotkey config for testing.
Future<void> initTestServices() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  await StorageService.instance.initForTest(':memory:');
  await HotkeyConfigService.instance.init();
}

/// Tear down test services.
Future<void> teardownTestServices() async {
  await StorageService.instance.close();
}

/// Insert a clipboard item directly into the DB and return it.
Future<ClipboardItem> insertTestItem(
  String content, {
  String type = 'text',
  bool pinned = false,
}) async {
  final id = await StorageService.instance.insertOrUpdate(content, type: type);
  if (pinned) {
    await StorageService.instance.togglePin(id);
  }
  final items = await StorageService.instance.fetchItems();
  return items.firstWhere((i) => i.id == id);
}

/// Mock the window_manager platform channel to avoid real window ops.
void mockWindowManager() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.leanflutter.plugins/window_manager'),
    (call) async {
      switch (call.method) {
        case 'ensureInitialized':
        case 'waitUntilReadyToShow':
        case 'show':
        case 'hide':
        case 'focus':
        case 'setAlwaysOnTop':
        case 'isVisible':
          return true;
        case 'getPosition':
          return {'x': 0.0, 'y': 0.0};
        case 'getSize':
          return {'width': 380.0, 'height': 480.0};
        case 'addListener':
        case 'removeListener':
          return null;
        default:
          return null;
      }
    },
  );
}

/// Mock the hotkey_manager platform channel.
void mockHotkeyManager() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.leanflutter.plugins/hotkey_manager'),
    (call) async {
      switch (call.method) {
        case 'register':
        case 'unregister':
        case 'unregisterAll':
          return null;
        default:
          return null;
      }
    },
  );
}

/// Mock the system clipboard channel.
void mockClipboard({String? initialText}) {
  String currentText = initialText ?? '';
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': currentText};
      }
      if (call.method == 'Clipboard.setData') {
        final args = call.arguments as Map;
        currentText = args['text'] as String? ?? '';
        return null;
      }
      return null;
    },
  );
}

/// Build a testable MaterialApp that wraps the CopyMan app structure.
/// Uses the real theme and route setup but avoids window/tray/hotkey deps.
Widget buildTestApp({Widget? home}) {
  return MaterialApp(
    title: 'CopyMan Test',
    themeMode: ThemeMode.light,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: home,
    onGenerateRoute: (settings) {
      if (settings.name == '/settings') {
        return MaterialPageRoute(
          builder: (_) => SettingsScreen(
            currentThemeMode: 'system',
            onThemeModeChanged: (_) {},
          ),
        );
      }
      return null;
    },
  );
}
