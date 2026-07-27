import 'dart:convert';

import 'reader_display_settings.dart';

/// Сериализация [ReaderDisplaySettings] ↔ JSON-строка.
///
/// Используется [AppPreferences] для хранения под ключом
/// `reader.displaySettings`. На чтение (decode) — tolerant:
/// неизвестные поля игнорируются, невалидные значения подменяются
/// defaults. Это критично для forward-compat: если в следующей
/// версии добавится поле, старые snapshot'ы не упадут.
class ReaderDisplaySettingsCodec {
  const ReaderDisplaySettingsCodec();

  String encode(ReaderDisplaySettings s) {
    return jsonEncode({
      'fontSize': s.fontSize,
      'lineHeight': s.lineHeight,
      'letterSpacing': s.letterSpacing,
      'wordSpacing': s.wordSpacing,
      'fontFamily': s.fontFamily,
      'textWidthPercent': s.textWidthPercent,
      'paddingHorizontal': s.paddingHorizontal,
      'paddingVertical': s.paddingVertical,
      'themeVariant': s.themeVariant,
      'brightness': s.brightness,
      'translationFontSize': s.translationFontSize,
      'showTranslation': s.showTranslation,
      'keepScreenOn': s.keepScreenOn,
      'readingMode': s.readingMode,
    });
  }

  ReaderDisplaySettings decode(String? raw) {
    if (raw == null || raw.isEmpty) return ReaderDisplaySettings.defaults;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      // Тема-вариант и шрифт: если в JSON невалидный id, откатываемся
      // на default, а не на this.themeVariant (которое могло быть
      // унаследовано из невалидного initial-state). Без этой проверки
      // copyWith сохранил бы невалидное значение (см. тест
      // "unknown themeVariant keeps default").
      final rawTheme = _asString(m['themeVariant']);
      final theme = rawTheme != null && ReaderDisplaySettings.themeVariants.contains(rawTheme)
          ? rawTheme
          : ReaderDisplaySettings.defaults.themeVariant;
      final rawFont = _asString(m['fontFamily']);
      final font = rawFont != null && ReaderDisplaySettings.fontFamilies.contains(rawFont)
          ? rawFont
          : ReaderDisplaySettings.defaults.fontFamily;

      return ReaderDisplaySettings(
        fontSize: _asDouble(m['fontSize']) ?? ReaderDisplaySettings.defaults.fontSize,
        lineHeight:
            _asDouble(m['lineHeight']) ?? ReaderDisplaySettings.defaults.lineHeight,
        letterSpacing: _asDouble(m['letterSpacing']) ??
            ReaderDisplaySettings.defaults.letterSpacing,
        wordSpacing:
            _asDouble(m['wordSpacing']) ?? ReaderDisplaySettings.defaults.wordSpacing,
        fontFamily: font,
        textWidthPercent: _asDouble(m['textWidthPercent']) ??
            ReaderDisplaySettings.defaults.textWidthPercent,
        paddingHorizontal: _asDouble(m['paddingHorizontal']) ??
            ReaderDisplaySettings.defaults.paddingHorizontal,
        paddingVertical: _asDouble(m['paddingVertical']) ??
            ReaderDisplaySettings.defaults.paddingVertical,
        themeVariant: theme,
        brightness:
            _asDouble(m['brightness']) ?? ReaderDisplaySettings.defaults.brightness,
        translationFontSize: _asDouble(m['translationFontSize']) ??
            ReaderDisplaySettings.defaults.translationFontSize,
        showTranslation: _asBool(m['showTranslation']) ??
            ReaderDisplaySettings.defaults.showTranslation,
        keepScreenOn:
            _asBool(m['keepScreenOn']) ?? ReaderDisplaySettings.defaults.keepScreenOn,
        readingMode: _asString(m['readingMode']) ??
            ReaderDisplaySettings.defaults.readingMode,
      ).copyWith(); // clamp на double-поля
    } catch (_) {
      // Любая ошибка декодирования → defaults. Не падаем, чтобы
      // пользователь не потерял доступ к чтению из-за битого JSON.
      return ReaderDisplaySettings.defaults;
    }
  }

  static double? _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static String? _asString(Object? v) => v is String ? v : null;

  static bool? _asBool(Object? v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.toLowerCase() == 'true';
    return null;
  }
}
