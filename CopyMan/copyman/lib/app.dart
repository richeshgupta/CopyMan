import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

class CopyManApp extends StatefulWidget {
  const CopyManApp({super.key});

  @override
  State<CopyManApp> createState() => CopyManAppState();
}

class CopyManAppState extends State<CopyManApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final val = await StorageService.instance.getSetting('theme_mode');
    if (val != null && mounted) {
      setState(() {
        _themeMode = _parseThemeMode(val);
      });
    }
  }

  ThemeMode _parseThemeMode(String val) {
    switch (val) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(String mode) {
    setState(() {
      _themeMode = _parseThemeMode(mode);
    });
    StorageService.instance.setSetting('theme_mode', mode);
  }

  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CopyMan',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
