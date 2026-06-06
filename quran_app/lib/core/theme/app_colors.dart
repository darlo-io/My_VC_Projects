import 'package:flutter/material.dart';

/// Цветовая палитра приложения, вдохновлённая тёмно-зелёной исламской эстетикой
/// с золотыми акцентами (как на макетах).
class AppColors {
  AppColors._();

  // === Backgrounds ===
  static const Color background = Color(0xFF0A1F1A);
  static const Color backgroundDeep = Color(0xFF051410);
  static const Color surface = Color(0xFF0F2A23);
  static const Color surfaceElevated = Color(0xFF133329);
  static const Color surfaceHigh = Color(0xFF1A4034);

  // === Primary green palette ===
  static const Color primary = Color(0xFF1F5C4A);
  static const Color primaryLight = Color(0xFF2E8068);
  static const Color primaryDark = Color(0xFF0E3A2E);

  // === Accent gold ===
  static const Color gold = Color(0xFFD4A84A);
  static const Color goldLight = Color(0xFFE8C77A);
  static const Color goldDark = Color(0xFFB5862C);
  static const Color goldMuted = Color(0xFF8C6A2A);

  // === Surah card variants (Top-of-home grid) ===
  static const Color cardRead = Color(0xFF1A4D3F);
  static const Color cardListen = Color(0xFF134E5E);
  static const Color cardLearn = Color(0xFF3D2E5C);
  static const Color cardTest = Color(0xFF5C4326);

  // === Text ===
  static const Color textPrimary = Color(0xFFEDE6D3);
  static const Color textSecondary = Color(0xFFB7A98F);
  static const Color textTertiary = Color(0xFF7E7563);
  static const Color textOnGold = Color(0xFF1A1408);

  // === States ===
  static const Color success = Color(0xFF4CAF82);
  static const Color warning = Color(0xFFD4A84A);
  static const Color error = Color(0xFFD05A4F);

  // === Borders ===
  static const Color border = Color(0x33D4A84A);
  static const Color borderSubtle = Color(0x1AD4A84A);
  static const Color borderStrong = Color(0x66D4A84A);

  // === Quran page background (mushaf) ===
  static const Color mushafBg = Color(0xFF0F2A23);
  static const Color mushafFrame = Color(0xFF1F5C4A);

  // === Gradients ===
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold, goldDark],
  );

  static const RadialGradient ornamentRadial = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [Color(0x33D4A84A), Color(0x00000000)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundDeep, background, backgroundDeep],
  );
}
