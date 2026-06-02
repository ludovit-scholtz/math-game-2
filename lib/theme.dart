import 'package:flutter/material.dart';

/// Central place for the playful, kid-friendly colour palette and theme.
class AppTheme {
  AppTheme._();

  static const double buttonRadius = 20;

  static const Color primary = Color(0xFF5B6CF0);
  static const Color secondary = Color(0xFFFF8A3D);
  static const Color correct = Color(0xFF2BB673);
  static const Color incorrect = Color(0xFFE5484D);
  static const Color background = Color(0xFFF4F6FF);
  static const Color darkBackground = Color(0xFF101427);
  static const Color darkSurface = Color(0xFF1B2138);

  static const List<Color> cardColors = [
    Color(0xFF5B6CF0),
    Color(0xFFFF8A3D),
    Color(0xFF2BB673),
    Color(0xFFB23CFD),
    Color(0xFF18B0C9),
  ];

  static ThemeData themeData() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      useMaterial3: true,
    );
    return _finishTheme(
      base,
      bodyColor: const Color(0xFF222452),
      cardColor: Colors.white,
    );
  }

  static ThemeData darkThemeData() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: const Color(0xFF91A0FF),
        secondary: const Color(0xFFFFB06F),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackground,
      useMaterial3: true,
    );
    return _finishTheme(
      base,
      bodyColor: const Color(0xFFEAF0FF),
      cardColor: darkSurface,
    );
  }

  static ThemeData _finishTheme(
    ThemeData base, {
    required Color bodyColor,
    required Color cardColor,
  }) {
    return base.copyWith(
      cardTheme: base.cardTheme.copyWith(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: bodyColor,
        displayColor: bodyColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: base.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: base.colorScheme.primary,
          side: BorderSide(color: base.colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: base.colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
    );
  }
}
