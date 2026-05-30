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
      ),
      scaffoldBackgroundColor: background,
      useMaterial3: true,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF222452),
        displayColor: const Color(0xFF222452),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
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
