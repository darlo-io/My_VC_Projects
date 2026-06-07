import 'package:shared_preferences/shared_preferences.dart';

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

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<void> remove(String key) => _prefs.remove(key);
}
