import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Цветовая палитра одной из тем Reader'а. Не зависит от
/// глобальной темы приложения: [themeVariant] живёт в
/// [ReaderDisplaySettings] и применяется **только** к зоне
/// чтения, чтобы навигация оставалась тёмной.
class ReaderPalette {
  const ReaderPalette({
    required this.id,
    required this.background,
    required this.surface,
    required this.text,
    required this.gold,
    required this.border,
  });

  final String id;
  final Color background;
  final Color surface;
  final Color text;
  final Color gold;
  final Color border;

  static const _dark = ReaderPalette(
    id: 'dark',
    background: AppColors.backgroundDeep,
    surface: AppColors.surface,
    text: AppColors.textPrimary,
    gold: AppColors.gold,
    border: AppColors.border,
  );

  static const _sepia = ReaderPalette(
    id: 'sepia',
    background: Color(0xFFF4ECD8),
    surface: Color(0xFFEFE5C8),
    text: Color(0xFF5B4636),
    gold: Color(0xFF8B6914),
    border: Color(0xFFD9C7A0),
  );

  static const _light = ReaderPalette(
    id: 'light',
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF1F2937),
    gold: Color(0xFF7C5E10),
    border: Color(0xFFE5E7EB),
  );

  static const _parchment = ReaderPalette(
    id: 'parchment',
    background: Color(0xFFEFE2C0),
    surface: Color(0xFFE8D9B0),
    text: Color(0xFF3D2F1F),
    gold: Color(0xFF8B6914),
    border: Color(0xFFC9B48B),
  );

  static const Map<String, ReaderPalette> all = {
    'dark': _dark,
    'sepia': _sepia,
    'light': _light,
    'parchment': _parchment,
  };

  /// Находит палитру по `themeVariant`. Неизвестный id →
  /// [dark] (фолбэк — навигация читабельна всегда).
  static ReaderPalette of(String id) => all[id] ?? _dark;
}
