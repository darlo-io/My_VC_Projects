import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_dark.dart';

/// Цветовая палитра одной из тем Reader'а. Не зависит от
/// глобальной темы приложения: [themeVariant] живёт в
/// [ReaderDisplaySettings] и применяется **только** к зоне
/// чтения, чтобы навигация оставалась светлой (вне Reader'а).
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

  /// «Dark» вариант Reader'а — использует **тёмную** палитру
  /// (`AppColorsDark`), потому что это специально тёмная тема для
  /// чтения (например, ночью). Основное приложение при этом
  /// остаётся на светлой палитре.
  static const _dark = ReaderPalette(
    id: 'dark',
    background: AppColorsDark.backgroundDeep,
    surface: AppColorsDark.surface,
    text: AppColorsDark.textPrimary,
    gold: AppColorsDark.gold,
    border: AppColorsDark.border,
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
  /// [dark] (фолбэк — глазам комфортно всегда).
  static ReaderPalette of(String id) => all[id] ?? _dark;
}
