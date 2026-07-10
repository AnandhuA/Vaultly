import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF4F46E5);
  static const secondary = Color(0xFF6366F1);
  static const accent = Color(0xFF22C55E);
  static const lightBackground = Color(0xFFF8FAFC);
  static const darkBackground = Color(0xFF0F172A);

  static ThemeData light() {
    return _theme(
      ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        tertiary: accent,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      lightBackground,
    );
  }

  static ThemeData dark() {
    return _theme(
      ColorScheme.fromSeed(
        seedColor: primary,
        primary: secondary,
        secondary: primary,
        tertiary: accent,
        surface: const Color(0xFF182033),
        brightness: Brightness.dark,
      ),
      darkBackground,
    );
  }

  static ThemeData _theme(ColorScheme scheme, Color scaffold) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }
}
