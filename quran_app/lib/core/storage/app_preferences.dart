import 'package:shared_preferences/shared_preferences.dart';

import '../../features/reader_settings/domain/reader_display_settings.dart';
import '../../features/reader_settings/domain/reader_display_settings_codec.dart';

/// Обёртка над SharedPreferences для простых пользовательских настроек
/// (тема, размер шрифта, выбранный чтец и т.д.).
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _kLanguageCode = 'app.languageCode';
  static const _kFirstLaunchDone = 'app.firstLaunchDone';
  static const _kFontSize = 'reader.fontSize';
  static const _kReciterId = 'audio.reciterId';
  static const _kTranslationLang = 'reader.translationLang';
  static const _kThemeMode = 'app.themeMode';
  static const _kCacheLimitMb = 'audio.cacheLimitMb';
  static const _kReadingMode = 'reader.readingMode';

  /// Снимок всех display-настроек Reader'а в виде JSON-строки.
  /// Сюда пишет [setDisplaySettings]; на чтение — [displaySettings]
  /// собирает объект из legacy-ключей + этого снимка (чтобы старые
  /// пользователи с `reader.fontSize = 24` не потеряли значение).
  static const _kDisplaySettings = 'reader.displaySettings';

  String? get languageCode => _prefs.getString(_kLanguageCode);

  Future<void> setLanguageCode(String? code) async {
    if (code == null) {
      await _prefs.remove(_kLanguageCode);
    } else {
      await _prefs.setString(_kLanguageCode, code);
    }
  }

  bool get isFirstLaunchDone => _prefs.getBool(_kFirstLaunchDone) ?? false;
  Future<void> setFirstLaunchDone(bool v) =>
      _prefs.setBool(_kFirstLaunchDone, v);

  double get fontSize => _prefs.getDouble(_kFontSize) ?? 28.0;
  Future<void> setFontSize(double v) => _prefs.setDouble(_kFontSize, v);

  String get reciterId => _prefs.getString(_kReciterId) ?? 'ar.alafasy';
  Future<void> setReciterId(String v) => _prefs.setString(_kReciterId, v);

  String get translationLang => _prefs.getString(_kTranslationLang) ?? 'ru';
  Future<void> setTranslationLang(String v) =>
      _prefs.setString(_kTranslationLang, v);

  String get themeMode => _prefs.getString(_kThemeMode) ?? 'dark';
  Future<void> setThemeMode(String v) => _prefs.setString(_kThemeMode, v);

  /// Лимит аудио-кеша в мегабайтах. По умолчанию 2 GB, как в ARCHITECTURE §14.
  int get cacheLimitMb => _prefs.getInt(_kCacheLimitMb) ?? 2048;
  Future<void> setCacheLimitMb(int mb) => _prefs.setInt(_kCacheLimitMb, mb);

  /// Режим чтения: `lineByLine` (построчный, как в Mushaf) или
  /// `book` (обычный — каждое слово идёт в одну длинную строку
  /// без центрирования). По умолчанию `lineByLine` — соответствует
  /// референсу `docs/images/read line by line.png`.
  String get readingMode =>
      _prefs.getString(_kReadingMode) ?? 'lineByLine';
  Future<void> setReadingMode(String v) =>
      _prefs.setString(_kReadingMode, v);

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> remove(String key) => _prefs.remove(key);

  // ─── ReaderDisplaySettings ────────────────────────────────────

  /// Снимок всех display-настроек. Источник истины для
  /// `readerDisplaySettingsProvider`. На чтение мигрирует со
  /// старых по-полевых ключей (`reader.fontSize` и т.п.), чтобы
  /// не потерять значения, выставленные до v0.4.
  ReaderDisplaySettings get displaySettings {
    const codec = ReaderDisplaySettingsCodec();
    final raw = _prefs.getString(_kDisplaySettings);
    if (raw != null && raw.isNotEmpty) {
      return codec.decode(raw);
    }
    // Миграция: собираем из legacy-ключей + defaults для всего
    // остального. Один раз; на следующей записи в `_kDisplaySettings`
    // legacy-ключи перестают быть источником истины.
    return codec.decode(null).copyWith(
      fontSize: fontSize,
      readingMode: readingMode,
      themeVariant: themeMode,
    );
  }

  Future<void> setDisplaySettings(ReaderDisplaySettings s) async {
    const codec = ReaderDisplaySettingsCodec();
    await _prefs.setString(_kDisplaySettings, codec.encode(s));
    // Дублируем в legacy-ключи поля, которые читаются напрямую
    // из других мест (bottom-sheet, тест, ...). Остальные поля
    // (`lineHeight`, `letterSpacing`, `themeVariant` из палитры
    // Reader'а, ...) — только в `displaySettings`.
    await _prefs.setDouble(_kFontSize, s.fontSize);
    await _prefs.setString(_kReadingMode, s.readingMode);
    await _prefs.setString(_kThemeMode, s.themeVariant);
  }

  /// Удалить все ключи, которые `AppPreferences` создаёт. Используется
  /// «Reset all data» в настройках. Ключи вроде `content.manifest.*`,
  /// которые пишут другие подсистемы, НЕ трогаем — они восстановятся
  /// при следующем bootstrap.
  Future<void> clearAll() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith('app.') ||
        k.startsWith('reader.') ||
        k.startsWith('audio.'));
    for (final k in keys) {
      await _prefs.remove(k);
    }
  }
}
