import 'package:flutter/material.dart';

class BloomlyColors {
  static const green = Color(0xFF128A3E);
  static const greenDark = Color(0xFF0C6B30);
  static const marigold = Color(0xFFE8943A);
  static const background = Color(0xFFF6F7F4);
  static const ink = Color(0xFF1C241C);
  static const muted = Color(0xFF667066);
  static const line = Color(0xFFE3E6DF);
  static const canvas = Color(0xFFE4E8E0);
  static const danger = Color(0xFFC2412D);
}

class BloomlyTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BloomlyColors.green,
      primary: BloomlyColors.green,
      surface: BloomlyColors.background,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BloomlyColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: BloomlyColors.background,
        foregroundColor: BloomlyColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        height: 64,
        indicatorColor: BloomlyColors.green.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? BloomlyColors.greenDark : BloomlyColors.muted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BloomlyColors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BloomlyColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BloomlyColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BloomlyColors.green, width: 1.4),
        ),
      ),
    );
  }
}
