import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class CopyManApp extends StatelessWidget {
  const CopyManApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CopyMan',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
