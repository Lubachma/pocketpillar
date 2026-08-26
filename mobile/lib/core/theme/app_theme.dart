import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The app's Material 3 theme, reusing the palette from Theme.swift.
abstract final class AppTheme {
  /// Theme.cornerRadius (cards, buttons).
  static const double cornerRadius = 14;

  /// Theme.smallCornerRadius (form fields).
  static const double smallCornerRadius = 8;

  static ThemeData light() =>
      _build(ColorScheme.fromSeed(seedColor: AppColors.accent));

  static ThemeData dark() => _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
    ),
  );

  static ThemeData _build(ColorScheme colorScheme) {
    final roundedLarge = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cornerRadius),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        shape: roundedLarge,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: roundedLarge,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(smallCornerRadius),
        ),
      ),
      extensions: const [AppSemanticColors.standard],
    );
  }
}
