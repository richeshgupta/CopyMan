import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF6366F1),
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: const Color(0xFF111827),
      secondary: const Color(0xFF6B7280),
      error: const Color(0xFFEF4444),
    ),
    scaffoldBackgroundColor: const Color(0xFFF3F4F6),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    ),
    dividerColor: const Color(0xFFE5E7EB),
    iconTheme: const IconThemeData(color: Color(0xFF6B7280)),
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF818CF8),
      onPrimary: Colors.white,
      surface: const Color(0xFF1E1E2E),
      onSurface: const Color(0xFFE2E8F0),
      secondary: const Color(0xFF94A3B8),
      error: const Color(0xFFF87171),
    ),
    scaffoldBackgroundColor: const Color(0xFF12121F),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E2E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF2D2D3F)),
      ),
    ),
    dividerColor: const Color(0xFF2D2D3F),
    iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
  );
}
