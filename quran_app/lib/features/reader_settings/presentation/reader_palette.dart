import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors_dark.dart';
import '../../../../l10n/generated/app_localizations.dart';

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

  /// Локализованное имя темы (единая точка правды — дублировалось в
  /// Reader-popup и в экране настроек чтения). Неизвестный id
  /// показываем как есть.
  String label(AppLocalizations t) => themeVariantLabel(t, id);
}

/// Локализованное имя темы по `id`. См. [ReaderPalette.label].
String themeVariantLabel(AppLocalizations t, String id) => switch (id) {
      'dark' => t.displaySettingsThemeDark,
      'sepia' => t.displaySettingsThemeSepia,
      'light' => t.displaySettingsThemeLight,
      'parchment' => t.displaySettingsThemeParchment,
      _ => id,
    };

/// Круглый свотч темы (фон + золотая рамка). Общая отрисовка для
/// Reader-popup и экрана настроек чтения.
class ThemeVariantSwatch extends StatelessWidget {
  const ThemeVariantSwatch({
    required this.palette,
    required this.size,
    this.borderWidth = 2,
    this.borderColor,
    this.check = false,
    this.checkColor,
    super.key,
  });

  final ReaderPalette palette;
  final double size;
  final double borderWidth;

  /// Переопределение цвета рамки (например, золотом выбранной темы).
  /// `null` → золото самой палитры [palette].
  final Color? borderColor;
  final bool check;
  final Color? checkColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.background,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? palette.gold,
          width: borderWidth,
        ),
      ),
      child: check
          ? Icon(Icons.check, color: checkColor ?? palette.gold, size: size / 2)
          : null,
    );
  }
}
