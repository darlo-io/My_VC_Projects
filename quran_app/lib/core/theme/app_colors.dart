import 'package:flutter/material.dart';

/// Светлая палитра приложения — теперь основная.
///
/// Раньше здесь был тёмно-зелёный набор (`#0A1F1A` background + золото).
/// После глобальной переделки под дизайн-макет (июнь 2026) приложение
/// полностью светлое: кремовый фон, тёмный текст, оливково-золотые
/// акценты. Структура полей сохранена, чтобы старые вызовы
/// `AppColors.gold`, `AppColors.textPrimary` и т.д. продолжали работать
/// без изменений в местах использования — значения просто стали
/// адаптированными для светлой темы.
///
/// Тёмная палитра осталась в `app_colors_dark.dart` для возможного
/// использования в тёмной теме в будущем (например, для ночного чтения).
class AppColors {
  AppColors._();

  // === Backgrounds ===
  /// Основной кремовый фон страницы.
  static const Color background = Color(0xFFFAF7F0);
  /// Чуть темнее кремовый — для нижних слоёв / нижней навигации.
  static const Color backgroundDeep = Color(0xFFF1ECE0);
  /// Белый — поверхности карточек.
  static const Color surface = Color(0xFFFFFFFF);
  /// Приподнятая поверхность (на 1 уровень).
  static const Color surfaceElevated = Color(0xFFF5F0E5);
  /// Сильно приподнятая (модалки, диалоги).
  static const Color surfaceHigh = Color(0xFFEBE5D6);

  // === Primary green palette (адаптировано для светлой темы) ===
  /// Тёмно-зелёный — для акцентов в пределах Reader'а и т.п.
  static const Color primary = Color(0xFF1F5C4A);
  static const Color primaryLight = Color(0xFF2E8068);
  static const Color primaryDark = Color(0xFF0E3A2E);

  // === Accent gold ===
  /// Золотой акцент — чуть темнее исходного для контраста на белом.
  static const Color gold = Color(0xFFB5862C);
  static const Color goldLight = Color(0xFFD4A84A);
  static const Color goldDark = Color(0xFF8C6A2A);
  static const Color goldMuted = Color(0xFF6B5430);

  // === Surah card variants (Top-of-home grid) ===
  static const Color cardRead = Color(0xFF1A4D3F);
  static const Color cardListen = Color(0xFF134E5E);
  static const Color cardLearn = Color(0xFF3D2E5C);
  static const Color cardTest = Color(0xFF5C4326);

  // === Tile gradients (мягкие пастельные для главного экрана) ===
  static const Color tileMintLight = Color(0xFFEAF1E2);
  static const Color tileMintDark = Color(0xFFD8E3C7);
  static const Color tileSkyLight = Color(0xFFE3EEF2);
  static const Color tileSkyDark = Color(0xFFC9DEE6);
  static const Color tileLavenderLight = Color(0xFFEDE8F2);
  static const Color tileLavenderDark = Color(0xFFDCD3E8);
  static const Color tileSandLight = Color(0xFFF6EFE2);
  static const Color tileSandDark = Color(0xFFE9DDC4);

  // === Accent olive (для активной навигации и прогресс-баров) ===
  static const Color accentOlive = Color(0xFF6B8E5A);
  static const Color accentDeepGreen = Color(0xFF3D5641);

  // === Text ===
  /// Почти чёрный — основной текст на светлом фоне.
  static const Color textPrimary = Color(0xFF1A1A1A);
  /// Тёплый серый — подписи, пояснения.
  static const Color textSecondary = Color(0xFF6B6657);
  /// Светлый серый — неактивные элементы.
  static const Color textTertiary = Color(0xFFA39B87);
  /// Тёмный текст на золотом фоне.
  static const Color textOnGold = Color(0xFF1A1408);

  // === States ===
  static const Color success = Color(0xFF4CAF82);
  static const Color warning = Color(0xFFB5862C);
  static const Color error = Color(0xFFD05A4F);

  // === Borders ===
  static const Color border = Color(0x33000000);
  static const Color borderSubtle = Color(0x14000000);
  static const Color borderStrong = Color(0x66000000);

  // === Quran page background (mushaf — paper-like) ===
  static const Color mushafBg = Color(0xFFFFFFFF);
  static const Color mushafFrame = Color(0xFFD4A84A);

  // === Surface variants (для навигации, тоглов, и т.д.) ===
  /// Приглушённая поверхность — фон активной вкладки в навигации.
  static const Color surfaceMuted = Color(0xFFEFEAE0);

  // === Continue Card pill ===
  static const Color progressBarTrack = Color(0xFFE6E0D0);

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
    colors: [background, backgroundDeep, background],
  );
}