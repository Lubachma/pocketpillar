import 'package:flutter/material.dart';

/// Palette reused from `ios/PocketPillar/Shared/Theme.swift`
/// (corresponding iOS system colors).
abstract final class AppColors {
  static const Color accent = Color(0xFF007AFF); // Theme.accent (blue)
  static const Color positive = Color(0xFF34C759); // Theme.positive (green)
  static const Color negative = Color(0xFFFF3B30); // Theme.negative (red)
  static const Color warning = Color(0xFFFF9500); // Theme.warning (orange)

  static const Color pillar1 = Color(0xFF00C7BE); // Theme.pillar1 (cyan)
  static const Color pillar2 = Color(0xFF007AFF); // Theme.pillar2 (blue)
  static const Color pillar3a = Color(0xFFAF52DE); // Theme.pillar3a (purple)
}

/// Business colors (semantic + 3 pillars) exposed via the theme.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.positive,
    required this.negative,
    required this.warning,
    required this.pillar1,
    required this.pillar2,
    required this.pillar3a,
  });

  static const AppSemanticColors standard = AppSemanticColors(
    positive: AppColors.positive,
    negative: AppColors.negative,
    warning: AppColors.warning,
    pillar1: AppColors.pillar1,
    pillar2: AppColors.pillar2,
    pillar3a: AppColors.pillar3a,
  );

  final Color positive;
  final Color negative;
  final Color warning;
  final Color pillar1;
  final Color pillar2;
  final Color pillar3a;

  @override
  AppSemanticColors copyWith({
    Color? positive,
    Color? negative,
    Color? warning,
    Color? pillar1,
    Color? pillar2,
    Color? pillar3a,
  }) {
    return AppSemanticColors(
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
      pillar1: pillar1 ?? this.pillar1,
      pillar2: pillar2 ?? this.pillar2,
      pillar3a: pillar3a ?? this.pillar3a,
    );
  }

  @override
  AppSemanticColors lerp(AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      pillar1: Color.lerp(pillar1, other.pillar1, t)!,
      pillar2: Color.lerp(pillar2, other.pillar2, t)!,
      pillar3a: Color.lerp(pillar3a, other.pillar3a, t)!,
    );
  }
}

/// Access to business colors: `context.appColors.pillar1`.
extension AppColorsContext on BuildContext {
  AppSemanticColors get appColors =>
      Theme.of(this).extension<AppSemanticColors>() ??
      AppSemanticColors.standard;
}
