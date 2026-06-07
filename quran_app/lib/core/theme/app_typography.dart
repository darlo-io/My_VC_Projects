import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Типографика приложения.
///
/// В MVP не зависит от сети: `google_fonts` не выполняет runtime fetching
/// (см. main.dart: `GoogleFonts.config.allowRuntimeFetching = false`).
/// Если соответствующий шрифт не заbundle'н — Flutter использует
/// platform default (Roboto на Android, SF на iOS, Segoe UI на Windows).
///
/// Чтобы вернуть оригинальный дизайн (Cormorant Garamond / Inter / Amiri),
/// положите .ttf в `assets/fonts/` и зарегистрируйте в pubspec.yaml:
///   fonts:
///     - family: CormorantGaramond
///       fonts:
///         - asset: assets/fonts/CormorantGaramond-Regular.ttf
///         - asset: assets/fonts/CormorantGaramond-SemiBold.ttf
///           weight: 600
class AppTypography {
  AppTypography._();

  static const _arabicFeatures = [
    FontFeature.enable('liga'),
    FontFeature.enable('calt'),
  ];

  static TextTheme textTheme(ColorScheme scheme) {
    return TextTheme(
      displayLarge: const TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.1,
      ),
      displayMedium: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      displaySmall: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineLarge: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      bodyLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodySmall: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
      labelMedium: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Крупный арабский текст. fontFamily 'Amiri' подцепится, если
  /// Amiri-Regular.ttf заbundle'н в assets; иначе — платформенный арабский.
  static TextStyle arabicDisplay({double size = 32}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: AppColors.gold,
        height: 1.6,
        fontFamily: 'Amiri',
        fontFeatures: _arabicFeatures,
      );

  /// Арабский текст аятов.
  static TextStyle arabicAyah({double size = 28}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 2.2,
        fontFamily: 'Amiri',
        fontFeatures: _arabicFeatures,
      );

  /// Имя суры.
  static TextStyle surahName({double size = 24}) => TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: AppColors.gold,
        fontFamily: 'Amiri',
        fontFeatures: _arabicFeatures,
      );
}
