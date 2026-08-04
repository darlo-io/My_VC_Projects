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

  /// Round 8: ID активного переводчика (translator.id в БД).
  /// Если не задан — fallback на legacy `translationLang` ('ru')
  /// → translator.id=1 (Кулиев, alquran.cloud или Quran.com).
  static const _kActiveTranslatorId = 'reader.activeTranslatorId';
  static const _kThemeMode = 'app.themeMode';
  static const _kCacheLimitMb = 'audio.cacheLimitMb';
  static const _kReadingMode = 'reader.readingMode';
  static const _kUseCustomDns = 'net.useCustomDns';
  static const _kCustomDohUrl = 'net.customDohUrl';

  /// Снимок всех display-настроек Reader'а в виде JSON-строки.
  /// Сюда пишет [setDisplaySettings]; на чтение — [displaySettings]
  /// собирает объект из legacy-ключей + этого снимка (чтобы старые
  /// пользователи с `reader.fontSize = 24` не потеряли значение).
  static const _kDisplaySettings = 'reader.displaySettings';

  /// `null` означает «использовать системную локаль» (определяется
  /// MaterialApp через `Locale.deviceLocale` или явно через LTR/RTL
  /// detect). Чтобы отличить «никогда не ставили» (по умолчанию) от
  /// «явно сбросили на системную» — не нужно; `null` покрывает оба.
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

  /// Round 8: ID активного переводчика (FK в `translators`).
  /// Default = 1 (Кулиев — наш seed переводчик).
  int get activeTranslatorId => _prefs.getInt(_kActiveTranslatorId) ?? 1;
  Future<void> setActiveTranslatorId(int id) =>
      _prefs.setInt(_kActiveTranslatorId, id);

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

  // ─── Custom DNS (Captive-bypass) ────────────────────────────────
  //
  // Помогает в сетях, где системный DNS-резолвер подменён
  // (captive portal, корпоративный прокси, гостиничный Wi-Fi).
  // Включается пользователем вручную в Settings → Audio → Custom DNS.
  // При включении все HTTP-запросы приложения (CDN аудио,
  // content-update, search) идут через указанный DoH-endpoint,
  // минуя локальный DNS-резолвер Android.

  /// Использовать ли пользовательский DNS-over-HTTPS.
  /// `false` (default) — обычный системный DNS.
  bool get useCustomDns => _prefs.getBool(_kUseCustomDns) ?? false;
  Future<void> setUseCustomDns(bool v) =>
      _prefs.setBool(_kUseCustomDns, v);

  /// URL DoH-endpoint. Должен поддерживать Cloudflare-style
  /// JSON API: `GET <url>?name=<host>&type=A` →
  /// `{"Answer":[{"data":"1.2.3.4"}]}`.
  /// Примеры: `https://1.1.1.1/dns-query`, `https://dns.google/resolve`,
  /// `https://9.9.9.9/dns-query`. По умолчанию `null`.
  String? get customDohUrl => _prefs.getString(_kCustomDohUrl);
  Future<void> setCustomDohUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await _prefs.remove(_kCustomDohUrl);
    } else {
      await _prefs.setString(_kCustomDohUrl, url);
    }
  }

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> remove(String key) => _prefs.remove(key);

  // ─── ReaderDisplaySettings ────────────────────────────────────

  /// Снимок всех display-настроек. Источник истины для
  /// `readerDisplaySettingsProvider`. На чтение мигрирует со
  /// старых по-полевых ключей (`reader.fontSize` и т.п.), чтобы
  /// не потерять значения, выставленные до v0.4.
  ///
  /// Round 9.6 (code review #R3): теперь кешируется через
  /// [_displaySettingsCache] — на каждый `ref.watch` UI-provider
  /// пересоздавался объект ~30 строк геттерами. В Reader'е этот
  /// getter вызывается **на каждый scroll-frame**, что потребляло
  /// CPU. Теперь после первого запроса — возвращается кешированный
  /// instance, инвалидируется при [setDisplaySettings]/[clearAll].
  ReaderDisplaySettings get displaySettings {
    final cached = _displaySettingsCache;
    if (cached != null) return cached;
    const codec = ReaderDisplaySettingsCodec();
    final raw = _prefs.getString(_kDisplaySettings);
    if (raw != null && raw.isNotEmpty) {
      _displaySettingsCache = codec.decode(raw);
      return _displaySettingsCache!;
    }
    // Миграция: собираем из legacy-ключей + defaults для всего
    // остального. Один раз; на следующей записи в `_kDisplaySettings`
    // legacy-ключи перестают быть источником истины.
    final migrated = codec.decode(null).copyWith(
      fontSize: fontSize,
      readingMode: readingMode,
      themeVariant: themeMode,
    );
    _displaySettingsCache = migrated;
    return migrated;
  }

  /// Round 9.6 (code review #R3): inline cache для [displaySettings].
  /// Reader вызывает getter на каждый scroll-frame — без cache это
  /// был бы JSON decode × N frames. Также помогает если несколько
  /// provider'ов одновременно делают `ref.watch(displaySettingsProvider)`.
  /// Инвалидируется в [setDisplaySettings] (т.к. legacy-ключи
  /// изменены) и в [clearAll] / [remove] (если ключ — именно
  /// displaySettings, например через Settings → Reset to defaults).
  ReaderDisplaySettings? _displaySettingsCache;

  Future<void> setDisplaySettings(ReaderDisplaySettings s) async {
    const codec = ReaderDisplaySettingsCodec();
    await _prefs.setString(_kDisplaySettings, codec.encode(s));
    _displaySettingsCache = s; // инвалидируем inline cache (R3).
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
        k.startsWith('audio.') ||
        k.startsWith('net.'));
    for (final k in keys) {
      await _prefs.remove(k);
    }
    // Round 9.6 (code review #R3): инвалидируем cache — после clearAll
    // prefs пустые, cache нужно пересчитать через миграцию с legacy.
    _displaySettingsCache = null;
  }
}
