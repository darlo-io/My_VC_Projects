import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Типографика приложения.
///
/// Шрифты (Amiri / Inter / Cormorant Garamond) забандлены в `assets/fonts/`
/// и зарегистрированы в `pubspec.yaml` секцией `fonts:`. Приложение
/// полностью offline-first — runtime fetching с CDN отключён.
class AppTypography {
  AppTypography._();

  static const _arabicFeatures = [
    FontFeature.enable('liga'),
    FontFeature.enable('calt'),
  ];

  static TextTheme textTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Крупный арабский текст (Amiri Bold).
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
