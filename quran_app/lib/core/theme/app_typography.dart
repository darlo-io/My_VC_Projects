import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Типографика приложения.
/// Основной шрифт для латиницы/кириллицы — Cormorant Garamond (заголовки)
/// и Inter (основной текст). Арабский — Amiri Quran.
class AppTypography {
  AppTypography._();

  static const _arabicFeatures = [
    FontFeature.enable('liga'),
    FontFeature.enable('calt'),
  ];

  static TextTheme textTheme(ColorScheme scheme) {
    final baseInter = GoogleFonts.inter;
    final baseCormorant = GoogleFonts.cormorantGaramond;
    final baseAmiri = GoogleFonts.amiri;

    return TextTheme(
      displayLarge: baseCormorant(
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.1,
      ),
      displayMedium: baseCormorant(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      displaySmall: baseCormorant(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineLarge: baseCormorant(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineMedium: baseCormorant(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      headlineSmall: baseCormorant(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: baseInter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: baseInter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: baseInter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      bodyLarge: baseInter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: baseInter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodySmall: baseInter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: baseInter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
      labelMedium: baseInter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: baseInter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textTertiary,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Стиль для крупного арабского текста (сура, заголовок)
  static TextStyle arabicDisplay({double size = 32}) => GoogleFonts.amiri(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: AppColors.gold,
        height: 1.6,
        fontFeatures: _arabicFeatures,
      );

  /// Стиль для арабского текста аятов (утхмани)
  static TextStyle arabicAyah({double size = 28}) => GoogleFonts.amiri(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 2.2,
        fontFeatures: _arabicFeatures,
      );

  /// Стиль для имени суры
  static TextStyle surahName({double size = 24}) => GoogleFonts.amiri(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: AppColors.gold,
        fontFeatures: _arabicFeatures,
      );
}
