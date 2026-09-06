import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/content/content_bootstrapper.dart';
import '../core/content/content_manifest.dart';
import '../core/content/content_update_service.dart';
import '../core/content/local_seed_service.dart';
import '../core/content/quran_manifest_api.dart';
import '../core/data/bookmarks_repository.dart';
import '../core/data/learning_repository.dart';
import '../core/data/notes_repository.dart';
import '../core/data/quran_repository.dart';
import '../core/data/search_repository.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/audio_cache_dao.dart';
import '../core/database/daos/search_dao.dart';
import '../core/database/daos/words_dao.dart';
import '../core/database/daos/translation_dao.dart';
import '../core/database/daos/surah_dao.dart';
import '../core/database/daos/ayah_dao.dart';
import '../core/database/daos/bookmark_dao.dart';
import '../core/database/daos/position_dao.dart';
import '../core/database/daos/reciter_dao.dart';
import '../core/database/daos/quran_com_reciter_dao.dart';
import '../core/database/daos/tafsir_dao.dart';
import '../core/database/daos/playback_sessions_dao.dart';
import '../core/database/daos/word_timings_dao.dart';
import '../core/database/daos/learning_dao.dart';
import '../core/database/daos/notes_dao.dart';
import '../features/reader_settings/domain/reader_display_settings.dart';
import '../core/database/models/last_read_position.dart';
import '../core/database/models/search_hits.dart';
import '../features/audio/data/quran_audio_handler.dart';
import '../features/test/data/quiz_service.dart';
import '../features/test/data/quiz_session.dart';
import '../core/networking/api_client.dart';
import '../core/networking/dns_aware_dio.dart';
import '../core/networking/doh_resolver.dart';
import '../core/storage/app_preferences.dart';
import '../features/audio/data/audio_cache.dart';
import '../features/audio/data/audio_player_controller.dart';
import '../features/audio/data/reciter_download_controller.dart';
import '../features/audio/data/reciters_repository.dart';
import '../features/audio/data/reciters_sync_service.dart';
import '../features/audio/data/quran_com_api.dart';
import '../features/tafsir/data/quran_com_tafsir_api.dart';
import '../features/tafsir/data/tafsirs_sync_service.dart';
import '../features/quran/data/ayahs_service.dart';
import '../features/quran/data/quran_com_translation_api.dart';
import '../features/quran/data/quran_translation_sync_service.dart';

/// DI-РіСЂР°С„ РїСЂРёР»РѕР¶РµРЅРёСЏ.

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

/// РџСЂРѕРІР°Р№РґРµСЂ РґР»СЏ [AppPreferences] вЂ” РµРґРёРЅС‹Р№ wrapper РЅР°Рґ
/// SharedPreferences РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЊСЃРєРёС… РЅР°СЃС‚СЂРѕРµРє (С‚РµРјР°,
/// СЂР°Р·РјРµСЂ С€СЂРёС„С‚Р°, РІС‹Р±СЂР°РЅРЅС‹Р№ С‡С‚РµС† Рё С‚.Рґ.).
///
/// IMPORTANT: Р­С‚Рѕ СЃРЅРѕРІР° РѕР±С‹С‡РЅС‹Р№ `Provider` (РЅРµ `NotifierProvider`).
/// РџРѕС‡РµРјСѓ: РїРѕРїС‹С‚РєРё СЃРґРµР»Р°С‚СЊ `setXxx`-РјРµС‚РѕРґС‹, РєРѕС‚РѕСЂС‹Рµ **СѓРІРµРґРѕРјР»СЏР»Рё
/// Р±С‹** РїРѕРґРїРёСЃС‡РёРєРѕРІ С‡РµСЂРµР· `state = ...` РёР»Рё `invalidateSelf`,
/// РїСЂРёРІРѕРґРёР»Рё Рє СЃР±СЂРѕСЃСѓ РЅР°РІРёРіР°С†РёРё РІ go_router (Reader РІС‹РєРёРґС‹РІР°Р»
/// РІ Home РїСЂРё СЃРјРµРЅРµ `readingMode`). РџСЂРёС‡РёРЅР° вЂ” РєР°РєРѕР№-С‚Рѕ РёР·
/// `ref.watch(appPreferencesProvider)` РІ РіСЂР°С„Рµ (LanguageNotifier,
/// cacheLimitMbProvider) РїРµСЂРµСЃРѕР±РёСЂР°Р»СЃСЏ РІ РЅРµРѕР¶РёРґР°РЅРЅРѕРј РїРѕСЂСЏРґРєРµ
/// СЃ `MaterialApp.router`, С‡С‚Рѕ С‚СЂРёРіРіРµСЂРёР»Рѕ redirect/refresh.
///
/// РЎРµР№С‡Р°СЃ `setXxx` вЂ” fire-and-forget (РїРёС€РµС‚ РІ SharedPreferences
/// Р±РµР· СѓРІРµРґРѕРјР»РµРЅРёСЏ Riverpod). UI, РєРѕС‚РѕСЂРѕРјСѓ РЅСѓР¶РЅРѕ **Р»РѕРєР°Р»СЊРЅРѕ**
/// РѕР±РЅРѕРІРёС‚СЊСЃСЏ РїСЂРё РёР·РјРµРЅРµРЅРёРё (РЅР°РїСЂРёРјРµСЂ, РїРµСЂРµРєР»СЋС‡РµРЅРёРµ reading-mode
/// РІ Reader), РёСЃРїРѕР»СЊР·СѓРµС‚ `StatefulWidget.setState` Рё СЃР°Рј
/// СЃРёРЅС…СЂРѕРЅРёР·РёСЂСѓРµС‚ СЃ `appPreferencesProvider` С‡РµСЂРµР· mount/refresh.
///
/// Р“Р»РѕР±Р°Р»СЊРЅРѕ Р·Р°РІРёСЃСЏС‰РёРµ РѕС‚ prefs СЌРєСЂР°РЅС‹ (Settings, Onboarding)
/// `StateNotifierProvider` РґР»СЏ `AppPreferences` вЂ” РїСЂРё Р»СЋР±РѕР№ Р·Р°РїРёСЃРё
/// (`setFontSize`, `setDisplaySettings`, `setLanguageCode`, ...) РІСЃРµ
/// `ref.watch(appPreferencesProvider)` dependents Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё
/// РїРѕР»СѓС‡Р°СЋС‚ СЃРІРµР¶РёР№ instance Рё СЂРµР±РёР»РґСЏС‚СЃСЏ. **РќРµ РЅСѓР¶РµРЅ**
/// `ref.invalidate(appPreferencesProvider)` РїРѕСЃР»Рµ Р·Р°РїРёСЃРё вЂ” `state =`
/// С‚СЂРёРіРіРµСЂРёС‚ notify СЃР°Рј.
///
/// Р”Рѕ СЌС‚РѕРіРѕ Р±С‹Р» `Provider<AppPreferences>` (Р±РµР· СѓРІРµРґРѕРјР»РµРЅРёР№) вЂ” Р·Р°РїРёСЃСЊ
/// С‡РµСЂРµР· `set*()` РјСѓС‚РёСЂРѕРІР°Р»Р° `SharedPreferences`, РЅРѕ Riverpod РЅРµ Р·РЅР°Р»
/// Рѕ РЅРµРѕР±С…РѕРґРёРјРѕСЃС‚Рё СЂРµР±РёР»РґР° dependents, Рё `readerDisplaySettingsProvider`
/// (РєРѕС‚РѕСЂС‹Р№ С‡РёС‚Р°РµС‚ `appPreferencesProvider.displaySettings` РіРµС‚С‚РµСЂ)
/// РѕС‚РґР°РІР°Р» **СЃС‚Р°СЂС‹Р№** snapshot, РїРѕРєР° РєС‚Рѕ-С‚Рѕ СЏРІРЅРѕ РЅРµ РІС‹Р·С‹РІР°Р»
/// `ref.invalidate`. РЎРј. bug report: В«РЅР°СЃС‚СЂРѕР№РєРё РЅРµ РїСЂРёРјРµРЅСЏСЋС‚СЃСЏ Рє
/// С‚РµРєСЃС‚Сѓ РљРѕСЂР°РЅР° РЅРё РІ РѕРґРЅРѕРј СЂРµР¶РёРјРµВ».
class AppPreferencesNotifier extends StateNotifier<AppPreferences> {
  AppPreferencesNotifier(SharedPreferences prefs, this._ref)
      : _prefs = prefs,
        super(AppPreferences(prefs));
  final SharedPreferences _prefs;
  final Ref _ref;

  // `set*` РјРµС‚РѕРґС‹ (РєСЂРѕРјРµ `setDisplaySettings`) РѕР±РЅРѕРІР»СЏСЋС‚ state
  // РЅРѕРІС‹Рј instance'РѕРј вЂ” dependents (`LanguageNotifier`,
  // `reciterIdProvider`, ...) С‚СЂРёРіРіРµСЂСЏС‚ СЂРµР±РёР»Рґ. РСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ
  // СЂРµРґРєРѕ (РїСЂРё СЃРјРµРЅРµ СЏР·С‹РєР° / С‚РµРјС‹ / С‡С‚РµС†Р°), Рё app-wide rebuild
  // РІ СЌС‚РёС… СЃС†РµРЅР°СЂРёСЏС… Р±РµР·РѕРїР°СЃРµРЅ (РЅРµС‚ push-СЂРѕСѓС‚РѕРІ РЅР° СЃС‚РµРєРµ).
  //
  // `setDisplaySettings` **РЅРµ** С‚СЂРёРіРіРµСЂРёС‚ state = new вЂ” СЌС‚Рѕ
  // Р»РѕРєР°Р»СЊРЅРѕ РёР·РјРµРЅСЏРµС‚ displaySettings, Рё dependents (`displaySettingsProvider`)
  // РїРѕРґС…РІР°С‚С‹РІР°СЋС‚ С‡РµСЂРµР· СЃРѕР±СЃС‚РІРµРЅРЅС‹Р№ `StateNotifier`. Р­С‚Рѕ РЅСѓР¶РЅРѕ,
  // РїРѕС‚РѕРјСѓ С‡С‚Рѕ СЃРјРµРЅР° displaySettings РїСЂРѕРёСЃС…РѕРґРёС‚ РЅР° РїСѓС‚Рё СЃ push-СЂРѕСѓС‚РѕРј
  // (settings РїРѕРІРµСЂС… Reader), Рё app-wide rebuild Р»РѕРјР°РµС‚ СЃС‚РµРє
  // GoRouter (РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РѕРєР°Р·С‹РІР°РµС‚СЃСЏ РЅР° РїСѓСЃС‚РѕРј Home вЂ” СЃРј. bug).

  /// Helper: Р·Р°РїРёСЃР°С‚СЊ РІ SharedPreferences Рё С‚СЂРёРіРіРµСЂРёС‚СЊ rebuild
/// dependents С‡РµСЂРµР· `state = new AppPreferences(_prefs)`.
/// РСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РґР»СЏ РІСЃРµС… `set*` РјРµС‚РѕРґРѕРІ, РљР РћРњР• С‚РµС…, РєРѕС‚РѕСЂС‹Рµ
/// РЅРµ РґРѕР»Р¶РЅС‹ РІС‹Р·С‹РІР°С‚СЊ app-wide rebuild (СЃРј. [setReadingMode]
/// Рё [setDisplaySettings]).
Future<void> _setAndNotify(Future<void> Function() write) async {
  await write();
  state = AppPreferences(_prefs);
}

Future<void> setDisplaySettings(ReaderDisplaySettings s) async {
  // Р‘РµР· `state = ...` вЂ” РќР• notify dependents. РћС‚РґРµР»СЊРЅС‹Р№
  // `displaySettingsProvider` СЃР°Рј notify'РёС‚ СЃРІРѕРё dependents
  // (Reader, Preview) СЃСЂР°Р·Сѓ РїРѕСЃР»Рµ Р·Р°РїРёСЃРё.
  await state.setDisplaySettings(s);
  _ref.read(displaySettingsProvider.notifier).refresh();
}

Future<void> setFontSize(double v) =>
    _setAndNotify(() => state.setFontSize(v));

Future<void> setLanguageCode(String? code) =>
    _setAndNotify(() => state.setLanguageCode(code));

  Future<void> setReadingMode(String mode) async {
    // **РќР•** С‚СЂРёРіРіРµСЂРёРј `state = ...` вЂ” СЌС‚Рѕ РІС‹Р·РІР°Р»Рѕ Р±С‹ app-wide
    // rebuild, РєРѕС‚РѕСЂС‹Р№ Р»РѕРјР°РµС‚ РЅР°РІРёРіР°С†РёСЋ GoRouter (РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ
    // РѕРєР°Р·С‹РІР°РµС‚СЃСЏ РЅР° РїСѓСЃС‚РѕРј Home). Р›РѕРєР°Р»СЊРЅС‹Р№ `setState` РІ
    // `ReaderScreenState` (С‡РµСЂРµР· `_readingMode`) СѓР¶Рµ РѕР±РЅРѕРІР»СЏРµС‚
    // UI. Р’ SharedPreferences Р·Р°РїРёСЃСЊ РЅСѓР¶РЅР° РґР»СЏ СЃРѕС…СЂР°РЅРµРЅРёСЏ
    // РјРµР¶РґСѓ СЃРµСЃСЃРёСЏРјРё. РќР° СЃР»РµРґСѓСЋС‰РµРј mount / refresh Reader
    // РїСЂРѕС‡РёС‚Р°РµС‚ СЃРІРµР¶РµРµ Р·РЅР°С‡РµРЅРёРµ С‡РµСЂРµР·
    // `appPreferencesProvider.readingMode` (СЃС‚Р°СЂС‚ СЃРµСЃСЃРёРё).
    await state.setReadingMode(mode);
  }

  Future<void> setActiveTranslatorId(int id) async {
    await state.setActiveTranslatorId(id);
  }

  // Custom DNS settings вЂ” РќР• С‚СЂРёРіРіРµСЂРёРј app-wide rebuild
  // Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё; РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ СЏРІРЅРѕ РЅР°Р¶РёРјР°РµС‚ Save РІ Settings,
  // Рё `dioProvider` СЃРґРµР»Р°РµС‚ `_ref.invalidate(...)` СЏРІРЅРѕ С‡РµСЂРµР·
  // РѕС‚РґРµР»СЊРЅС‹Р№ РїСѓС‚СЊ, С‡С‚РѕР±С‹ UI РЅРµ РїРµСЂРµСЃРѕР±РёСЂР°Р»СЃСЏ.

  /// Р’РєР»СЋС‡Р°РµС‚/РІС‹РєР»СЋС‡Р°РµС‚ [DnsAwareInterceptor]. РЎРј. `appPreferencesProvider.useCustomDns`.
  ///
  /// вљ пёЏ РќР• РґРµР»Р°РµРј `state = AppPreferences(_prefs)` вЂ” СЌС‚Рѕ app-wide
  /// rebuild, РєРѕС‚РѕСЂС‹Р№ Р»РѕРјР°РµС‚ GoRouter-stack (СЃРј. round-7/8 hotfix).
  /// Р’РјРµСЃС‚Рѕ СЌС‚РѕРіРѕ РёРЅРєСЂРµРјРµРЅС‚РёРј [dnsSettingsVersionProvider] вЂ”
  /// `dioProvider` СЃР»СѓС€Р°РµС‚ РµРіРѕ Рё РїРµСЂРµcРѕР·РґР°С‘С‚ `Dio` С‚РѕС‡РµС‡РЅРѕ, Р±РµР·
  /// РєР°СЃРєР°РґР° РЅР° `apiClientProvider` / `audioCacheProvider` /
  /// `audioPlayerControllerProvider`.
  Future<void> setUseCustomDns(bool v) async {
    developer.log(
      'setUseCustomDns start v=$v',
      name: 'AppPreferencesNotifier',
    );
    await state.setUseCustomDns(v);
    developer.log(
      'setUseCustomDns state updated',
      name: 'AppPreferencesNotifier',
    );
    _ref.read(dnsSettingsVersionProvider.notifier).update((s) => s + 1);
    developer.log(
      'setUseCustomDns dnsSettingsVersionProvider bumped '
      'to ${_ref.read(dnsSettingsVersionProvider) + 0}',
      name: 'AppPreferencesNotifier',
    );
  }

  /// РЈСЃС‚Р°РЅР°РІР»РёРІР°РµС‚ DoH-endpoint URL. РџСЂРё РІРєР»СЋС‡РµРЅРёРё
  /// [setUseCustomDns] `true` РІСЃРµ HTTP-Р·Р°РїСЂРѕСЃС‹ РёРґСѓС‚ С‡РµСЂРµР· РЅРµРіРѕ.
  Future<void> setCustomDohUrl(String? url) async {
    developer.log(
      'setCustomDohUrl start url=$url',
      name: 'AppPreferencesNotifier',
    );
    await state.setCustomDohUrl(url);
    developer.log(
      'setCustomDohUrl state updated',
      name: 'AppPreferencesNotifier',
    );
    _ref.read(dnsSettingsVersionProvider.notifier).update((s) => s + 1);
  }

Future<void> setTranslationLang(String lang) =>
    _setAndNotify(() => state.setTranslationLang(lang));

Future<void> setReciterId(String id) async {
  // Р—Р°РїРёСЃС‹РІР°РµРј РЅР°РїСЂСЏРјСѓСЋ РІ SharedPreferences **Р‘Р•Р—** `state = AppPreferences(...)`
  // вЂ” РїРѕС‚РѕРјСѓ С‡С‚Рѕ app-wide rebuild Р»РѕРјР°РµС‚ GoRouter-stack
  // (РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РѕРєР°Р·С‹РІР°РµС‚СЃСЏ РЅР° РїСѓСЃС‚РѕРј Home вЂ” СЃРј. round-7
  // hotfix report). Dependents, РєРѕС‚РѕСЂС‹Рј РЅСѓР¶РµРЅ СЃРІРµР¶РёР№ `reciterId`,
  // С‡РёС‚Р°СЋС‚ РµРіРѕ РЅР°РїСЂСЏРјСѓСЋ С‡РµСЂРµР· `appPreferencesProvider.reciterId`
  // (РіРµС‚С‚РµСЂ), РєРѕС‚РѕСЂС‹Р№ `SharedPreferences` СЃРёРЅС…СЂРѕРЅРёР·РёСЂСѓРµС‚
  // СЃРёРЅС…СЂРѕРЅРЅРѕ.
  await state.setReciterId(id);
  // Р‘РµР· `state = AppPreferences(_prefs)`. РЎРј. РєРѕРјРјРµРЅС‚Р°СЂРёР№ РІ
  // setReadingMode (line 126) вЂ” Р°РЅР°Р»РѕРіРёС‡РЅС‹Р№ РїР°С‚С‚РµСЂРЅ РґР»СЏ
  // РёР·Р±РµР¶Р°РЅРёСЏ app-wide rebuild РЅР° РїРѕР»СЊР·РѕРІР°С‚РµР»СЊСЃРєРёС… actions
  // (РІС‹Р±РѕСЂ СЂРµРєС‚РѕСЂР°, РїРµСЂРµРєР»СЋС‡РµРЅРёРµ СЏР·С‹РєР° С‡С‚РµРЅРёСЏ).
}

Future<void> setThemeMode(String mode) =>
    _setAndNotify(() => state.setThemeMode(mode));

  Future<void> setFirstLaunchDone(bool v) async {
    // БЕЗ `state = AppPreferences(_prefs)` — app-wide rebuild в этот
    // момент (сразу после `bootstrap()` на чистой установке)
    // пересобирал `contentBootstrapperProvider` и провоцировал
    // гоночный цикл редиректов `/bootstrap` ↔ `/onboarding`
    // (пользователь застревал на «Загрузка Корана…»). Значение
    // читается напрямую через геттер `isFirstLaunchDone` — синхронно
    // и всегда свежо, подписчики не нужны.
    await state.setFirstLaunchDone(v);
  }

Future<void> setCacheLimitMb(int mb) =>
    _setAndNotify(() => state.setCacheLimitMb(mb));

  Future<void> clearAll() async {
    await state.clearAll();
    state = AppPreferences(_prefs);
  }
}

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferences>(
  (ref) => AppPreferencesNotifier(ref.watch(sharedPreferencesProvider), ref),
);

/// Bump-counter, РєРѕС‚РѕСЂС‹Р№ `setUseCustomDns` / `setCustomDohUrl`
/// РІ `AppPreferencesNotifier` РёРЅРєСЂРµРјРµРЅС‚СЏС‚. `dnsSettingsProvider`
/// watch'РёС‚ СЌС‚РѕС‚ counter вЂ” РёРЅРєСЂРµРјРµРЅС‚ РїРµСЂРµcРѕР·РґР°С‘С‚ РµРіРѕ, Рё РїСЂРё
/// РЅРѕРІРѕРј РІС‹С‡РёСЃР»РµРЅРёРё РјС‹ С‡РёС‚Р°РµРј СЃРІРµР¶РµРµ Р·РЅР°С‡РµРЅРёРµ РёР·
/// `appPreferencesProvider` Р‘Р•Р— `state = AppPreferences(_prefs)`
/// (С‚.Рµ. Р±РµР· app-wide rebuild).
///
/// Р’ РѕР±С‹С‡РЅРѕРј lifecycle (Р±РµР· РїРѕР»СЊР·РѕРІР°С‚РµР»СЊСЃРєРѕРіРѕ РёР·РјРµРЅРµРЅРёСЏ DNS)
/// counter РЅРµ РјРµРЅСЏРµС‚СЃСЏ в†’ dependents РєРµС€РёСЂСѓСЋС‚СЃСЏ.
final dnsSettingsVersionProvider = StateProvider<int>((_) => 0);

/// РР·РѕР»РёСЂРѕРІР°РЅРЅС‹Р№ sub-selector РґР»СЏ DNS-РЅР°СЃС‚СЂРѕРµРє. РЎСѓС‰РµСЃС‚РІСѓРµС‚
/// С‡С‚РѕР±С‹ `dioProvider` РјРѕРі watch'РёС‚СЊ **С‚РѕР»СЊРєРѕ** `useCustomDns`/
/// Рё `customDohUrl` (Р° РЅРµ РІРµСЃСЊ `appPreferencesProvider` С†РµР»РёРєРѕРј)
/// вЂ” РёРЅР°С‡Рµ Р»СЋР±РѕРµ РёР·РјРµРЅРµРЅРёРµ `reciterId` / `fontSize` /
/// `themeMode` РїСЂРёРІРѕРґРёР»Рѕ Р±С‹ Рє РїРµСЂРµcРѕР·РґР°РЅРёСЋ `Dio` Рё invalidate
/// РєР°СЃРєР°РґР° dependents (РІРєР»СЋС‡Р°СЏ `audioPlayerControllerProvider`,
/// С‡РµР№ `dispose()` РјРѕРі СЂРѕРЅСЏС‚СЊ Drift вЂ” СЃРј. round-8 hotfix).
final dnsSettingsProvider = Provider<({bool enabled, String? url})>((ref) {
  // Watch the bump-counter, not the underlying prefs (which never
  // notify when `setUseCustomDns` writes without `state = ...`).
  ref.watch(dnsSettingsVersionProvider);
  final prefs = ref.read(appPreferencesProvider);
  return (
    enabled: prefs.useCustomDns,
    url: prefs.customDohUrl,
  );
});

/// `Dio`-РєР»РёРµРЅС‚ РґР»СЏ **JSON-API** (Quran API, content-updates, search).
/// Р РµР°РєС‚РёРІРЅРѕ РїРµСЂРµСЃРѕР·РґР°С‘С‚СЃСЏ **С‚РѕР»СЊРєРѕ** РїСЂРё РёР·РјРµРЅРµРЅРёРё DNS-РЅР°СЃС‚СЂРѕРµРє
/// (СЃРј. [dnsSettingsProvider]).
///
/// Р’РђР–РќРћ: `audioCacheProvider` РќР• Р·Р°РІРёСЃРёС‚ РѕС‚ СЌС‚РѕРіРѕ РїСЂРѕРІР°Р№РґРµСЂР° вЂ”
/// СЃРј. [audioDioProvider] Рё [audioCacheProvider]. РРЅР°С‡Рµ cascade
/// invalidate РЅР° СЃРјРµРЅРµ DNS СѓРЅРёС‡С‚РѕР¶Р°Р» Р±С‹ `audioPlayerControllerProvider`
/// (StateNotifier) Рё РµРіРѕ Drift-РѕРїРµСЂР°С†РёРё РІ `dispose()` (СЃРј.
/// round-9 hotfix).
final dioProvider = Provider<Dio>((ref) {
  final dns = ref.watch(dnsSettingsProvider);
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    ),
  );

  if (dns.enabled && (dns.url ?? '').isNotEmpty) {
    // Р РµР·РѕР»РІРµСЂ Р¶РёРІС‘С‚ РЅР° РѕС‚РґРµР»СЊРЅРѕРј Dio-РёРЅСЃС‚Р°РЅСЃРµ, С‡С‚РѕР±С‹ РЅРµ
    // Р·Р°РєРѕР»СЊС†РµРІР°С‚СЊСЃСЏ (РµСЃР»Рё Р±С‹ РѕРЅ С€С‘Р» С‡РµСЂРµР· `dioProvider`,
    // С‚РѕС‚ Р¶Рµ DnsAwareAdapter Р±С‹ РїРµСЂРµС…РІР°С‚РёР» РЅР°С€ СЃРѕР±СЃС‚РІРµРЅРЅС‹Р№
    // Р·Р°РїСЂРѕСЃ Рё Р·Р°СЂРµР·РѕР»РІРёР» Р±С‹ `1.1.1.1` С‡РµСЂРµР· `1.1.1.1` вЂ”
    // Р±РµСЃРєРѕРЅРµС‡РЅР°СЏ СЂРµРєСѓСЂСЃРёСЏ).
    final resolverDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        responseType: ResponseType.json,
      ),
    );
    final resolver = DohResolver(
      dio: resolverDio,
      endpoint: dns.url!,
    );
    dio.httpClientAdapter = DnsAwareAdapter(
      inner: IOHttpClientAdapter(),
      resolver: resolver,
    );
  }
  return dio;
});

/// РћР±С‘СЂРЅСѓС‚С‹Р№ РІ [ApiClient] РґР»СЏ СѓРґРѕР±РЅРѕРіРѕ JSON API.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(dio: ref.watch(dioProvider)),
);

/// **РЎС‚Р°С‚РёС‡РµСЃРєРёР№** `Dio` РґР»СЏ Р°СѓРґРёРѕ-РєРµС€Р° Рё РїР»РµРµСЂР°. **РќР• Р·Р°РІРёСЃРёС‚**
/// РЅРё РѕС‚ `dnsSettingsProvider`, РЅРё РѕС‚ `appPreferencesProvider` вЂ”
/// С‡С‚РѕР±С‹ invalidate cascade РЅР° СЃРјРµРЅРµ DNS **РЅРёРєРѕРіРґР°** РЅРµ РґРѕС…РѕРґРёР»
/// РґРѕ `audioCacheProvider` / `audioPlayerControllerProvider`
/// (StateNotifier, С‡РµР№ `dispose()` РјРѕР¶РµС‚ СЂРѕРЅСЏС‚СЊ Drift вЂ” СЃРј.
/// round-9 hotfix).
///
/// **РљРѕРјРїСЂРѕРјРёСЃСЃ**: РїСЂРё РІРєР»СЋС‡С‘РЅРЅРѕРј Custom DNS Р°СѓРґРёРѕ-Р·Р°РіСЂСѓР·РєРё РёРґСѓС‚
/// С‡РµСЂРµР· СЃРёСЃС‚РµРјРЅС‹Р№ DNS (С‚РѕС‚ Р¶Рµ captive DNS, С‡С‚Рѕ Рё РґРѕ СЌС‚РѕРіРѕ
/// С„РёРєСЃР°). Р­С‚Рѕ Р·РЅР°С‡РёС‚, С‡С‚Рѕ DoH РЅР° audio-РєРµС€ РЅРµ СЂР°Р±РѕС‚Р°РµС‚. JSON
/// API РїСЂРё СЌС‚РѕРј С…РѕРґРёС‚ С‡РµСЂРµР· `dioProvider` в†’ DnsAwareAdapter.
/// Р­С‚Рѕ СЂР°Р·СѓРјРЅС‹Р№ trade-off: cache-miss-СЃС‚СЂР°РґР°РµС‚ РјРµРЅСЊС€Рµ, С‡РµРј
/// РєСЂР°С€Р°С‰РёР№СЃСЏ UI РЅР° РєР°Р¶РґРѕРј РєР»РёРєРµ РїРѕ Settings.
final audioDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 60),
      responseType: ResponseType.bytes,
    ),
  );
});

final quranManifestApiProvider = Provider<QuranManifestApi>(
  (ref) => QuranManifestApi(),
);

/// РђСЃРёРЅС…СЂРѕРЅРЅР°СЏ Р·Р°РіСЂСѓР·РєР° РїРµСЂРµРІРѕРґР° С‚РµРєСѓС‰РµРіРѕ Р°СЏС‚Р° РЅР° СЏР·С‹РєРµ РїСЂРёР»РѕР¶РµРЅРёСЏ.
/// Р’РѕР·РІСЂР°С‰Р°РµС‚ `null` РµСЃР»Рё РїРµСЂРµРІРѕРґР° РЅРµС‚ РІ Р‘Р” вЂ” С‚РѕРіРґР° РІ [_AyahPanel]
/// РјРµР»РєРёР№ СЃР°Р±С‚Р°Р№С‚Р» РїСЂРѕСЃС‚Рѕ РЅРµ РїРѕРєР°Р·С‹РІР°РµС‚СЃСЏ.
final ayahTranslationProvider =
    FutureProvider.family<String?, SurahAyahRef>(
  (ref, key) async {
    // Р‘РµСЂС‘Рј СЏР·С‹Рє РёР· [AppPreferences] вЂ” РѕРЅ СЃРёРЅС…СЂРѕРЅРёР·РёСЂРѕРІР°РЅ СЃ Р»РѕРєР°Р»СЊСЋ
    // РїСЂРёР»РѕР¶РµРЅРёСЏ С‡РµСЂРµР· [LocaleSettingsNotifier]. `WidgetsBinding` С‚СѓС‚
    // РЅРµ СЃСЂР°Р±РѕС‚Р°РµС‚ вЂ” РЅР°Рј РЅСѓР¶РµРЅ BuildContext, Р° РІ РїСЂРѕРІР°Р№РґРµСЂРµ РµРіРѕ РЅРµС‚.
    final prefs = ref.watch(appPreferencesProvider);
    final lang = prefs.languageCode ?? 'ru';
    final dao = ref.watch(translationDaoProvider);
    final ayah = await ref.watch(ayahTextProvider(key).future);
    if (ayah == null) return null;
    return dao.getForAyah(ayahId: ayah.id, languageCode: lang);
  },
);

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) {
    final db = AppDatabase();
    ref.onDispose(db.close);
    return db;
  },
);

final surahDaoProvider =
    Provider<SurahDao>((ref) => ref.watch(appDatabaseProvider).surahDao);
final ayahDaoProvider =
    Provider<AyahDao>((ref) => ref.watch(appDatabaseProvider).ayahDao);
final bookmarkDaoProvider =
    Provider<BookmarkDao>((ref) => ref.watch(appDatabaseProvider).bookmarkDao);
final translationDaoProvider = Provider<TranslationDao>(
  (ref) => ref.watch(appDatabaseProvider).translationDao,
);

/// Round 8: список всех translators из БД, отсортированный
/// (русские первыми, потом по nameRu/name).
/// Используется в Settings → выбор перевода.
/// `ref.watch(translatorsListRefreshProvider)` нужен для
/// инвалидации после добавления новых translators (cold start seed).
final translatorsListProvider = FutureProvider<List<Translator>>((
  ref,
) async {
  ref.watch(translatorsListRefreshProvider);
  return ref.watch(translationDaoProvider).getAllTranslatorsOrdered();
});

/// Round 8: lazy fetch service для переводов с Quran.com API.
/// Singleton через Riverpod.
final quranTranslationSyncServiceProvider =
    Provider<QuranTranslationSyncService>((ref) {
  return QuranTranslationSyncService(
    translationDao: ref.watch(translationDaoProvider),
    api: ref.watch(quranComTranslationApiProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

/// Round 8: reactive sync state — UI может показывать прогресс
/// "Загружаем перевод N из 114 сур".
///
/// CRITICAL (code review #B3, 2026-07-31): в `ref.onDispose` обязательно
/// вызываем `removeListener` — иначе на каждом invalidate provider'а
/// остаётся «висящий» listener на `service.state`, что ведёт к утечке
/// памяти и потенциальным вызовам на закрытый StreamController.
final translationSyncStateProvider =
    StreamProvider<TranslationSyncState>((ref) {
  final service = ref.watch(quranTranslationSyncServiceProvider);
  final controller = StreamController<TranslationSyncState>();
  controller.add(service.state.value);
  void onChange() {
    if (!controller.isClosed) controller.add(service.state.value);
  }

  service.state.addListener(onChange);
  ref.onDispose(() {
    service.state.removeListener(onChange);
    controller.close();
  });
  return controller.stream;
});

/// Round 8: Quran.com translation API client.
final quranComTranslationApiProvider =
    Provider<QuranComTranslationApi>((ref) => QuranComTranslationApi());

/// Round 9: общий Quran.com API client (для fetchChapters,
/// fetchVersesByChapter, fetchAyahMetadataByChapter). Используется
/// `AyahsService` для lazy load аятов.
final quranComApiProvider = Provider<QuranComApi>((ref) => QuranComApi());

/// Round 9.2: lazy fetch service для аятов (Quran.com API).
/// При первом открытии сур в Reader загружает text_uthmani,
/// text_normalized, page, juz, hizb. Singleton через Riverpod.
final ayahsServiceProvider = Provider<AyahsService>((ref) {
  return AyahsService(
    ayahDao: ref.watch(ayahDaoProvider),
    quranComApi: ref.watch(quranComApiProvider),
    db: ref.watch(appDatabaseProvider),
  );
});

/// Round 9.2: reactive state для UI прогресса lazy fetch аятов.
///
/// CRITICAL (code review #B3, 2026-07-31): добавлен `removeListener` в
/// `ref.onDispose` для предотвращения утечки listener'ов на
/// `service.state` при invalidate provider'а.
final ayahsSyncStateProvider = StreamProvider<AyahsSyncState>((ref) {
  final service = ref.watch(ayahsServiceProvider);
  final controller = StreamController<AyahsSyncState>();
  controller.add(service.state.value);
  void onChange() {
    if (!controller.isClosed) controller.add(service.state.value);
  }

  service.state.addListener(onChange);
  ref.onDispose(() {
    service.state.removeListener(onChange);
    controller.close();
  });
  return controller.stream;
});

/// Round 8: invalidation-флаг для `translatorsListProvider`.
/// При добавлении новых translators (cold start seed) этот flag
/// сбрасывается, и UI обновит список. Без этого `FutureProvider`
/// продолжал бы показывать старый snapshot с 2 переводами.
final translatorsListRefreshProvider = StateProvider<int>((ref) => 0);
final positionDaoProvider = Provider<PositionDao>(
  (ref) => ref.watch(appDatabaseProvider).positionDao,
);

/// Stream of the last read position enriched with the surrounding
/// surah metadata. Exposed as an `AsyncValue<LastReadPosition>` so
/// the home screen can `.value` it and fall back to
/// [LastReadPosition.empty] on the first frame.
final lastReadPositionProvider =
    StreamProvider<LastReadPosition>((ref) {
  return ref.watch(quranRepositoryProvider).watchLastReadPosition();
});

/// **РР·РѕР»РёСЂРѕРІР°РЅРЅС‹Р№** StateNotifier РґР»СЏ display-РЅР°СЃС‚СЂРѕРµРє Reader'Р°.
///
/// `appPreferencesProvider` вЂ” РіР»РѕР±Р°Р»СЊРЅС‹Р№, РѕС‚ РЅРµРіРѕ Р·Р°РІРёСЃСЏС‚ РґРµСЃСЏС‚РєРё
/// РїСЂРѕРІР°Р№РґРµСЂРѕРІ (`LanguageNotifier`, `reciterIdProvider`, ...). РџСЂРё
/// РµРіРѕ РѕР±РЅРѕРІР»РµРЅРёРё (`state = new AppPreferences`) Riverpod РґРµР»Р°РµС‚
/// app-wide rebuild, С‡С‚Рѕ РІ race СЃ `context.pop()` Р»РѕРјР°РµС‚ СЃС‚РµРє
/// GoRouter вЂ” РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РѕРєР°Р·С‹РІР°РµС‚СЃСЏ РЅР° РїСѓСЃС‚РѕРј Home (СЃРј. bug
/// report РѕС‚ 16.06.2026: В«РЅР°СЃС‚СЂРѕР№РєРё РЅРµ РїСЂРёРјРµРЅСЏСЋС‚СЃСЏ Рє С‚РµРєСЃС‚Сѓ РљРѕСЂР°РЅР°В»).
///
/// `displaySettingsProvider` вЂ” **Р»РѕРєР°Р»СЊРЅС‹Р№** StateNotifier СЃ
/// СЃРѕР±СЃС‚РІРµРЅРЅС‹Рј `state`. Р—Р°РїРёСЃСЊ `set*` РѕР±РЅРѕРІР»СЏРµС‚ С‚РѕР»СЊРєРѕ РµРіРѕ
/// dependents (`Reader`, `PreviewAyah`), Р±РµР· РєР°СЃРєР°РґР° РЅР° РѕСЃС‚Р°Р»СЊРЅРѕР№
/// app. РџРѕСЌС‚РѕРјСѓ `setDisplaySettings` РёР· settings-СЌРєСЂР°РЅР° Р±РµР·РѕРїР°СЃРЅРѕ
/// С‚СЂРёРіРіРµСЂРёС‚ СЂРµР±РёР»Рґ `Reader`'Р° (РѕРЅ РЅР° СЃС‚РµРєРµ РЅРёР¶Рµ) Рё РЅРµ Р»РѕРјР°РµС‚
/// `GoRouter`.
class DisplaySettingsNotifier extends StateNotifier<ReaderDisplaySettings> {
  DisplaySettingsNotifier(Ref ref)
      : _ref = ref,
        super(_loadInitial(ref));

  final Ref _ref;

  static ReaderDisplaySettings _loadInitial(Ref ref) {
    final prefs = ref.read(appPreferencesProvider);
    return prefs.displaySettings;
  }

  Future<void> set(ReaderDisplaySettings s) async {
    // `set` РІ `appPreferencesProvider` (С‡РµСЂРµР· `setDisplaySettings`)
    // РќР• РІС‹Р·С‹РІР°РµС‚ `state = new AppPreferences(...)` вЂ” С‚РѕР»СЊРєРѕ РїРёС€РµС‚
    // РІ SharedPreferences Рё РєР»Р°РґС‘С‚ РЅРѕРІС‹Р№ snapshot РІ `state`
    // (С‡РµСЂРµР· `refresh()`). Р—РґРµСЃСЊ РјС‹ РґРµР»Р°РµРј **Р»РѕРєР°Р»СЊРЅРѕРµ** РѕР±РЅРѕРІР»РµРЅРёРµ
    // вЂ” `state = s` вЂ” С‡С‚Рѕ С‚СЂРёРіРіРµСЂРёС‚ СЂРµР±РёР»Рґ С‚РѕР»СЊРєРѕ dependents
    // `displaySettingsProvider` (Reader, Preview).
    await _ref.read(appPreferencesProvider.notifier).setDisplaySettings(s);
    state = s;
  }

  /// Обновить ТОЛЬКО in-memory state, без записи в SharedPreferences.
  ///
  /// Для непрерывных жестов ([Slider.onChanged]): каждый тик драга
  /// иначе гоняет JSON-encode + 4 platform-channel записи (~50–60/с).
  /// Персист выполняет [set] один раз в `onChangeEnd`.
  void setLocal(ReaderDisplaySettings s) {
    state = s;
  }

  /// РџСЂРёРЅСѓРґРёС‚РµР»СЊРЅС‹Р№ refresh вЂ” РІС‹Р·С‹РІР°РµС‚СЃСЏ РёР· `AppPreferencesNotifier.setDisplaySettings`
  /// РµСЃР»Рё С‡С‚Рѕ-С‚Рѕ (РЅР°РїСЂРёРјРµСЂ, `clearAll`) РёР·РјРµРЅРёР»Рѕ displaySettings РІ
  /// SharedPreferences РёР·РІРЅРµ РЅР°С€РµРіРѕ РїСЂСЏРјРѕРіРѕ flow.
  void refresh() {
    final current = _ref.read(appPreferencesProvider).displaySettings;
    if (current != state) {
      state = current;
    }
  }
}

final displaySettingsProvider =
    StateNotifierProvider<DisplaySettingsNotifier, ReaderDisplaySettings>(
  DisplaySettingsNotifier.new,
);

/// РЎРЅРёРјРѕРє display-РЅР°СЃС‚СЂРѕРµРє Reader'Р° (fontSize, lineHeight,
/// themeVariant, ...). РСЃС‚РѕС‡РЅРёРє РёСЃС‚РёРЅС‹ вЂ” **`displaySettingsProvider`**
/// (РёР·РѕР»РёСЂРѕРІР°РЅРЅС‹Р№ StateNotifier), Р° РќР• `appPreferencesProvider` вЂ”
/// С‡С‚РѕР±С‹ РёР·Р±РµР¶Р°С‚СЊ app-wide rebuild РїСЂРё Р·Р°РїРёСЃРё.
///
/// Р—Р°РїРёСЃСЊ РёР· `appPreferencesProvider.setDisplaySettings` С‚РµРїРµСЂСЊ
/// РґРµР»Р°РµС‚ **Р»РѕРєР°Р»СЊРЅС‹Р№** `state =` РІ `displaySettingsProvider`,
/// Рё С‚РѕР»СЊРєРѕ dependents (`Reader`, `Preview`) СЂРµР±РёР»РґСЏС‚СЃСЏ.
final readerDisplaySettingsProvider =
    Provider<ReaderDisplaySettings>((ref) {
  return ref.watch(displaySettingsProvider);
});

/// [QuizService] tied to the singleton [AppDatabase]. The Quiz
/// screen watches a `FutureProvider` over its `buildSession`
/// method to load a fresh session whenever the user re-enters
/// the screen.
final quizServiceProvider = Provider<QuizService>((ref) {
  return QuizService(ref.watch(appDatabaseProvider));
});

/// Async loader for a fresh [QuizSession]. Re-creates a new
/// session on every watch вЂ” the screen calls
/// `ref.invalidate(quizSessionProvider)` to start a new round
/// after the user finishes one.
final quizSessionProvider = FutureProvider<QuizSession?>((ref) async {
  final lang = ref.watch(appPreferencesProvider).translationLang;
  return ref.watch(quizServiceProvider).buildSession(
        languageCode: lang,
      );
});
final reciterDaoProvider = Provider<ReciterDao>(
  (ref) => ref.watch(appDatabaseProvider).reciterDao,
);

/// Quran.com audio metadata (Sprint 1.5). РћС‚РґРµР»СЊРЅР°СЏ С‚Р°Р±Р»РёС†Р° РґР»СЏ
/// per-reciter URL'РѕРІ Quran.com CDN. Static mapping С‡РµСЂРµР·
/// [kMp3quranToQuranCom] СЂР°Р±РѕС‚Р°РµС‚ Р±РµР· РЅРµС‘; СЌС‚Р° С‚Р°Р±Р»РёС†Р° вЂ” РґР»СЏ
/// overrides Рё custom-РёРјРїРѕСЂС‚РѕРІ.
final quranComReciterDaoProvider = Provider<QuranComReciterDao>(
  (ref) => ref.watch(appDatabaseProvider).quranComReciterDao,
);
final audioCacheDaoProvider = Provider<AudioCacheDao>(
  (ref) => ref.watch(appDatabaseProvider).audioCacheDao,
);

/// SearchDao (Sprint 2.7) вЂ” FTS5 fulltext search РїРѕ ayahs, translations,
/// words, tafsirs. Р’РёСЂС‚СѓР°Р»СЊРЅС‹Рµ С‚Р°Р±Р»РёС†С‹ `ayahs_fts` / `translations_fts` /
/// `words_fts` / `tafsirs_fts` СЃРѕР·РґР°СЋС‚СЃСЏ РІ [AppDatabase._createFts]
/// СЃ С‚СЂРёРіРіРµСЂР°РјРё РґР»СЏ Р°РІС‚Рѕ-СЃРёРЅС…СЂРѕРЅРёР·Р°С†РёРё.
final searchDaoProvider = Provider<SearchDao>(
  (ref) => ref.watch(appDatabaseProvider).searchDao,
);

final playbackSessionsDaoProvider = Provider<PlaybackSessionsDao>(
  (ref) => ref.watch(appDatabaseProvider).playbackSessionsDao,
);
final wordsDaoProvider = Provider<WordsDao>(
  (ref) => ref.watch(appDatabaseProvider).wordsDao,
);
final wordTimingsDaoProvider = Provider<WordTimingsDao>(
  (ref) => ref.watch(appDatabaseProvider).wordTimingsDao,
);

final learningDaoProvider = Provider<LearningDao>(
  (ref) => ref.watch(appDatabaseProvider).learningDao,
);

final notesDaoProvider = Provider<NotesDao>(
  (ref) => ref.watch(appDatabaseProvider).notesDao,
);

/// TafsirDao (Sprint 2 — Quran.com Tafsir integration).
/// Работает с таблицами `tafsir_sources` и `tafsirs` (см. `tables.dart`).
final tafsirDaoProvider = Provider<TafsirDao>(
  (ref) => ref.watch(appDatabaseProvider).tafsirDao,
);

/// Quran.com Tafsir API client (Sprint 2). Создаётся со встроенным
/// `Dio` (статические 8s/12s таймауты). Для тестов можно
/// инжектить свой `Dio` через override.
final quranComTafsirApiProvider = Provider<QuranComTafsirApi>(
  (ref) => QuranComTafsirApi(),
);

/// Singleton воркер фоновой синхронизации списка тафсиров.
/// State — `ValueNotifier<TafsirsSyncState>`, см. `tafsirs_sync_service.dart`.
/// Round 9.6 (code review #M6): добавлен `sharedPreferencesProvider`
/// для персистинга `_lastSyncedAt` между сессиями.
final tafsirsSyncServiceProvider = Provider<TafsirsSyncService>((ref) {
  return TafsirsSyncService(
    ref.watch(tafsirDaoProvider),
    ref.watch(quranComTafsirApiProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final recitersRepositoryProvider = Provider<RecitersRepository>(
  (ref) => RecitersRepository(
    ref.watch(reciterDaoProvider),
    quranComDao: ref.watch(quranComReciterDaoProvider),
  ),
);

/// Р¤РѕРЅРѕРІС‹Р№ РІРѕСЂРєРµСЂ СЃРёРЅС…СЂРѕРЅРёР·Р°С†РёРё mp3quran-СЂРµРєС‚РѕСЂРѕРІ. Singleton, РїРѕС‚РѕРјСѓ
/// С‡С‚Рѕ Сѓ РЅРµРіРѕ РµСЃС‚СЊ in-memory `ValueNotifier<RecitersSyncState>` вЂ” РїСЂРё
/// РєР°Р¶РґРѕРј [ForceRefresh]-СЃС‚РёР»Рµ РёРЅРІР°Р»РёРґРёСЂРѕРІР°РЅРёРё СЃРѕСЃС‚РѕСЏРЅРёРµ С‚РµСЂСЏР»РѕСЃСЊ Р±С‹.
///
/// `ref.watch(recitersSyncServiceProvider)` РїРѕРґРїРёСЃР°РЅ UI, РєРѕС‚РѕСЂС‹Р№
/// РјРѕР¶РµС‚ РїРѕРєР°Р·Р°С‚СЊ В«СЃРёРЅС…СЂРѕРЅРёР·Р°С†РёСЏ РёРґС‘С‚В» / В«РїРѕСЃР»РµРґРЅРёР№ sync Р±С‹Р» XВ».
final recitersSyncServiceProvider = Provider<RecitersSyncService>((ref) {
  return RecitersSyncService(ref.watch(recitersRepositoryProvider));
});

final audioCacheProvider = Provider<AudioCache>(
  (ref) => AudioCache(
    // `audioDioProvider` (РќР• `apiClientProvider`) вЂ” СЌС‚Рѕ СЂР°Р·СЂС‹РІР°РµС‚
    // cascade invalidate РґРѕ `audioPlayerControllerProvider`
    // (StateNotifier, С‡РµР№ `dispose()` РјРѕРі СЂРѕРЅСЏС‚СЊ Drift вЂ” СЃРј.
    // round-9 hotfix). РџСЂРё СЃРјРµРЅРµ DNS DoH Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё
    // РїРѕРґРјРµРЅСЏРµС‚ `httpClientAdapter` С‡РµСЂРµР· [DnsAwareAdapter].
    dio: ref.watch(audioDioProvider),
    dao: ref.watch(audioCacheDaoProvider),
    // `prefs` РЅСѓР¶РµРЅ РґР»СЏ LRU-eviction РІ play-path. Provider
    // РёРЅР¶РµРєС‚РёСЂСѓРµС‚СЃСЏ, С‡С‚РѕР±С‹ РёР·Р±РµР¶Р°С‚СЊ РїСЂСЏРјРѕР№ Р·Р°РІРёСЃРёРјРѕСЃС‚Рё РѕС‚
    // SharedPreferences РІ audio-РїРѕРґСЃРёСЃС‚РµРјРµ.
    prefs: ref.watch(appPreferencesProvider),
  ),
);

/// РЎС‚СЂРёРј ID СЂРµРєС‚РѕСЂРѕРІ, Сѓ РєРѕС‚РѕСЂС‹С… СЃРєР°С‡Р°РЅС‹ РІСЃРµ 114 MP3.
/// РСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РІ reciter picker'Рµ РґР»СЏ РёРєРѕРЅРєРё В«РїРѕР»РЅРѕСЃС‚СЊСЋ Р·Р°РіСЂСѓР¶РµРЅВ».
final fullyCachedRecitersProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(audioCacheProvider).watchFullyCachedReciters(),
);

/// РљРѕРЅС‚СЂРѕР»Р»РµСЂ С„РѕРЅРѕРІРѕР№ Р·Р°РіСЂСѓР·РєРё РІСЃРµС… MP3 РґР»СЏ СЂРµРєС‚РѕСЂР° (prefetch all).
/// Singleton, РѕРґРёРЅ СЃР»РѕС‚ вЂ” СЃРј. [ReciterDownloadController].
final reciterDownloadControllerProvider =
    StateNotifierProvider<ReciterDownloadController, ReciterDownloadState>(
  (ref) {
    final controller = ReciterDownloadController(
      cache: ref.watch(audioCacheProvider),
      reciters: ref.watch(recitersRepositoryProvider),
    );
    ref.onDispose(controller.cancel);
    return controller;
  },
);

final audioPlayerControllerProvider =
    StateNotifierProvider<AudioPlayerController, AudioPlayerState>(
  (ref) => AudioPlayerController(
    cache: ref.watch(audioCacheProvider),
    reciters: ref.watch(recitersRepositoryProvider),
    surahDao: ref.watch(surahDaoProvider),
    sessions: ref.watch(playbackSessionsDaoProvider),
  ),
);

/// [QuranAudioHandler] is a singleton owned by [audio_service] (constructed
/// in main.dart via AudioService.init). The provider exposes the same
/// instance to the widget tree.
final quranAudioHandlerProvider = Provider<QuranAudioHandler>((ref) {
  throw UnimplementedError(
    'quranAudioHandlerProvider must be overridden in main.dart '
    'after AudioService.init() has produced the handler instance.',
  );
});

final recitersStreamProvider = StreamProvider(
  (ref) => ref.watch(recitersRepositoryProvider).watchAll(),
);

/// РљР»СЋС‡ РґР»СЏ [ayahTextProvider] вЂ” РїР°СЂР° (surahId, ayahNumber).
class SurahAyahRef {
  const SurahAyahRef({required this.surahId, required this.ayahNumber});
  final int surahId;
  final int ayahNumber;
  @override
  bool operator ==(Object other) =>
      other is SurahAyahRef &&
      other.surahId == surahId &&
      other.ayahNumber == ayahNumber;
  @override
  int get hashCode => Object.hash(surahId, ayahNumber);
}

/// РљР»СЋС‡ РґР»СЏ [_surahByIdProvider] вЂ” РїСЂРѕСЃС‚Рѕ ID СЃСѓСЂС‹ (РґР»СЏ FutureProvider.family).
class SurahIdKey {
  const SurahIdKey(this.id);
  final int id;
  @override
  bool operator ==(Object other) =>
      other is SurahIdKey && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// Provider РґР»СЏ Р°СЃРёРЅС…СЂРѕРЅРЅРѕР№ Р·Р°РіСЂСѓР·РєРё СЃСѓСЂС‹ РїРѕ id. РСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ
/// [_SurahAyahSelectors] РґР»СЏ РїРѕР»СѓС‡РµРЅРёСЏ Р°РєС‚СѓР°Р»СЊРЅРѕРіРѕ `ayahCount` вЂ”
/// РґРѕ РІС‹Р·РѕРІР° `playSurah()` (РєРѕРіРґР° `state.surah` РµС‰С‘ РїСѓСЃС‚РѕР№).
final surahByIdProvider = FutureProvider.family<Surah?, SurahIdKey>(
  (ref, key) => ref.watch(surahDaoProvider).getById(key.id),
);

/// РђСЃРёРЅС…СЂРѕРЅРЅР°СЏ Р·Р°РіСЂСѓР·РєР° Р°СЏС‚Р° РёР· Р‘Р” (Uthmani-С‚РµРєСЃС‚) РґР»СЏ РѕС‚РѕР±СЂР°Р¶РµРЅРёСЏ РІ
/// [_AyahPanel]. РСЃРїРѕР»СЊР·СѓРµС‚ FutureProvider.family вЂ” Riverpod
/// Р°РІС‚РѕРјР°С‚РёС‡РµСЃРєРё РґРµРґСѓРїР»РёС†РёСЂСѓРµС‚ РѕРґРёРЅР°РєРѕРІС‹Рµ РєР»СЋС‡Рё, РїРѕСЌС‚РѕРјСѓ РїСЂРё
/// СЃРјРµРЅРµ currentAyah РЅРµ РїСЂРѕРёСЃС…РѕРґРёС‚ Р»РёС€РЅРёС… Р·Р°РїСЂРѕСЃРѕРІ.
final ayahTextProvider = FutureProvider.family<Ayah?, SurahAyahRef>(
  (ref, key) async {
    final dao = ref.watch(ayahDaoProvider);
    return dao.getBySurahAndNumber(key.surahId, key.ayahNumber);
  },
);

/// РџРѕС‚РѕРє РѕР±С‰РµРіРѕ СЂР°Р·РјРµСЂР° Р°СѓРґРёРѕ-РєРµС€Р° РІ Р±Р°Р№С‚Р°С… (РґР»СЏ UI).
final cacheTotalBytesProvider = StreamProvider<int>((ref) {
  return ref.watch(audioCacheProvider).watchTotalBytes();
});

/// РўРµРєСѓС‰РёР№ Р»РёРјРёС‚ РєРµС€Р° РІ РјРµРіР°Р±Р°Р№С‚Р°С….
final cacheLimitMbProvider = StateProvider<int>((ref) {
  return ref.watch(appPreferencesProvider).cacheLimitMb;
});

final contentUpdateServiceProvider = Provider<ContentUpdateService>((ref) {
  // Берём `appVersion` из PackageInfo (через `appVersionProvider`),
  // иначе — fallback из `pubspec.yaml: version` (1.0.0+1 →
  // strip build → '1.0.0'). `appVersionProvider` обновляется в
  // `main.dart` через `PackageInfo.fromPlatform()` после старта
  // приложения; до этого момента используется fallback.
  final pkg = ref.watch(appVersionProvider);
  return ContentUpdateService(
    api: ref.watch(quranManifestApiProvider),
    manifestRepository: ref.watch(contentManifestRepositoryProvider),
    appVersion: pkg ?? '1.0.0',
  );
});

/// РўРµРєСѓС‰Р°СЏ РІРµСЂСЃРёСЏ РїСЂРёР»РѕР¶РµРЅРёСЏ (`pubspec.yaml: version`).
/// РРЅРёС†РёР°Р»РёР·РёСЂСѓРµС‚СЃСЏ РІ `main.dart` С‡РµСЂРµР· `PackageInfo.fromPlatform()`.
/// РСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РґР»СЏ [min_app_version] РїСЂРѕРІРµСЂРєРё РІ
/// [ContentUpdateService].
final appVersionProvider = StateProvider<String?>((ref) => null);

final contentManifestRepositoryProvider =
    Provider<ContentManifestRepository>(
  (ref) => ContentManifestRepository(ref.watch(appPreferencesProvider)),
);

final contentBootstrapperProvider = Provider<ContentBootstrapper>(
  (ref) {
    // Round 9.5 (code review #C3): все зависимости передаются
    // через конструктор — инициализация атомарна, нет late
    // mutation. `audioCache` и `recitersSyncService` опциональны
    // (для тестирования / offline-first режима).
    return ContentBootstrapper(
      db: ref.watch(appDatabaseProvider),
      surahDao: ref.watch(surahDaoProvider),
      ayahDao: ref.watch(ayahDaoProvider),
      translationDao: ref.watch(translationDaoProvider),
      wordsDao: ref.watch(wordsDaoProvider),
      wordTimingsDao: ref.watch(wordTimingsDaoProvider),
      manifestRepository: ref.watch(contentManifestRepositoryProvider),
      recitersRepository: ref.watch(recitersRepositoryProvider),
      localSeed: LocalSeedService(),
      contentUpdateService: ref.watch(contentUpdateServiceProvider),
      audioCache: ref.watch(audioCacheProvider),
      recitersSyncService: ref.watch(recitersSyncServiceProvider),
    );
  },
);

/// РџРѕР»РЅС‹Р№ СЃР±СЂРѕСЃ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: wipes user-data tables +
/// РѕС‡РёС‰Р°РµС‚ Р°СѓРґРёРѕ-РєРµС€ + СЃР±СЂР°СЃС‹РІР°РµС‚ SharedPreferences (РєСЂРѕРјРµ
/// РєРѕРЅС‚РµРЅС‚-РјР°РЅРёС„РµСЃС‚Р°, РєРѕС‚РѕСЂС‹Р№ РІРѕСЃСЃС‚Р°РЅРѕРІРёС‚СЃСЏ РЅР° СЃР»РµРґСѓСЋС‰РµРј
/// bootstrap). РСЃРїРѕР»СЊР·СѓРµС‚СЃСЏ РёР· SettingsScreen В«Reset all dataВ».
/// РџРѕСЃР»Рµ РІС‹Р·РѕРІР° СЃС‚РѕРёС‚ РїРµСЂРµР·Р°РїСѓСЃС‚РёС‚СЊ `contentReadyProvider`,
/// С‡С‚РѕР±С‹ UI Р·Р°РјРµС‚РёР» РёР·РјРµРЅРµРЅРёСЏ.
///
/// РџСЂРёРЅРёРјР°РµС‚ [WidgetRef] РёР· Riverpod вЂ” РЅР° С‚РµРєСѓС‰РёР№ РјРѕРјРµРЅС‚
/// РµРґРёРЅСЃС‚РІРµРЅРЅС‹Р№ РІС‹Р·С‹РІР°СЋС‰РёР№ (SettingsScreen) Р¶РёРІС‘С‚ РІ widget tree,
/// Рё С‚Р°С‰РёС‚СЊ `ProviderScope.containerOf(context)` С‚СѓРґР° Р±С‹Р»Рѕ Р±С‹
/// Р»РёС€РЅРёРј С€СѓРјРѕРј. РџСЂРё РїРµСЂРµРЅРѕСЃРµ Р»РѕРіРёРєРё РІ non-widget-РєРѕРЅС‚РµРєСЃС‚
/// РґРѕСЃС‚Р°С‚РѕС‡РЅРѕ Р±СѓРґРµС‚ СЃРґРµР»Р°С‚СЊ РѕР±С‘СЂС‚РєСѓ, РїСЂРёРЅРёРјР°СЋС‰СѓСЋ [Ref].
Future<void> resetAllUserData(WidgetRef ref) async {
  await ref.read(appDatabaseProvider).wipeUserData();
  await ref.read(audioCacheProvider).clearAll();
  // `AppPreferences.clearAll` СЃС‚РёСЂР°РµС‚ `app.*` / `reader.*` / `audio.*`
  // РєР»СЋС‡Рё РІ SharedPreferences (РІРєР»СЋС‡Р°СЏ `app.firstLaunchDone`).
  // Р‘РµР· СЌС‚РѕРіРѕ `isFirstLaunchDone` РѕСЃС‚Р°С‘С‚СЃСЏ `true` РїРѕСЃР»Рµ reset Рё
  // РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РќР• РїРѕРїР°РґР°РµС‚ РЅР° /onboarding, Р° СЃСЂР°Р·Сѓ РЅР° / вЂ”
  // СЃРј. `app_router.dart:_run()`. `clearAll` С‚РµРїРµСЂСЊ СЃР°Рј
  // СѓРІРµРґРѕРјР»СЏРµС‚ dependents С‡РµСЂРµР· `state = AppPreferences(_prefs)`
  // РІ `AppPreferencesNotifier`.
  await ref.read(appPreferencesProvider.notifier).clearAll();
  // РџРµСЂРµСЃРѕР·РґР°С‘Рј РіРѕС‚РѕРІРѕРµ СЃРѕСЃС‚РѕСЏРЅРёРµ вЂ” С‚РµРїРµСЂСЊ isReady() == true
  // (РєРѕРЅС‚РµРЅС‚ РµСЃС‚СЊ), РЅРѕ last_position == null, Р·Р°РєР»Р°РґРєРё РїСѓСЃС‚С‹Рµ Рё С‚.Рґ.
  ref.invalidate(contentReadyProvider);
}

// ----- Repositories (ARCHITECTURE В§4) -----
// UI С‡РёС‚Р°РµС‚ С‚РѕР»СЊРєРѕ СЌС‚Рё Provider'С‹, РЅРµ DAO РЅР°РїСЂСЏРјСѓСЋ.

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository(
    surahDao: ref.watch(surahDaoProvider),
    ayahDao: ref.watch(ayahDaoProvider),
    translationDao: ref.watch(translationDaoProvider),
    positionDao: ref.watch(positionDaoProvider),
    wordsDao: ref.watch(wordsDaoProvider),
  );
});

final bookmarksRepositoryProvider = Provider<BookmarksRepository>((ref) {
  return BookmarksRepository(ref.watch(bookmarkDaoProvider));
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(notesDaoProvider));
});

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(ref.watch(learningDaoProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  // SearchRepository Р С—РЎР‚Р С‘Р Р…Р С‘Р СР В°Р ВµРЎвЂљ РЎвЂћРЎС“Р Р…Р С”РЎвЂ Р С‘Р Вµ Р Р†Р СР ВµРЎРѓРЎвЂљР С• DAOs, РЎвЂЎРЎвЂљР С•Р В±РЎвЂ№ Р Р…Р Вµ РЎвЂљРЎРЏР Р…РЎС“РЎвЂљРЎРЉ
  // РЎвЂ Р С‘Р С”Р В»Р С‘РЎвЂЎР ВµРЎРѓР С”Р С‘Р в„– Р С‘Р СР С—Р С•РЎР‚РЎвЂљ (РЎРѓР С. Р С”Р С•Р СР СР ВµР Р…РЎвЂљР В°РЎР‚Р С‘Р в„– Р Р† SearchRepository). Р вЂ”Р Т‘Р ВµРЎРЉ
  // Р СРЎвЂ№ Р В±Р С‘Р Р…Р Т‘Р С‘Р С DAO-Р СР ВµРЎвЂљР С•Р Т‘РЎвЂ№ Р Р† plain-РЎвЂћРЎС“Р Р…Р С”РЎвЂ Р С‘Р Вµ РЎвЂЎР ВµРЎР‚Р ВµР В· tearoff (`dao.method`)
  // РІР‚вЂќ `this` РЎвЂћР С‘Р ВµРЎРѓР С‘РЎР‚РЎС“Р ВµРЎвЂљРЎРѓРЎРЏ Р В°Р Р†РЎвЂљР С•Р СР В°РЎвЂљР С‘РЎвЂЎР ВµРЎРѓР С”Р С‘.
  // Р РЋР С—Р СР Р†Р ВµР Р…Р Р…Р С• (Sprint 2.7): FTS5 РІ default. Р СџР ВµРЎР‚Р ВµР В»РЎРЉ Р В·Р В°Р СР ВµР Р…РЎРЏР ВµРЎвЂљ РЎРѓР ВµРЎР‚Р Р†Р ВµРЎРѓ
  // (РЎвЂЎР ВµРЎР‚Р ВµР В· `select-searchSurahsFn` etc.) Р Р…Р В° `searchDao` Р С‘ FTS5-Р СР ВµРЎвЂљР С•Р Т‘РЎвЂ№.
  final searchDao = ref.watch(searchDaoProvider);
  final surahDao = ref.watch(surahDaoProvider);
  return SearchRepository(
    searchSurahsFn: (q, {limit = 10}) async {
      // Р В¤Р В°Р В»Р В»Р В±РЎРЊР ВµР С”: Р Р…Р ВµРЎвЂљ FTS5-Р С‘Р Р…Р Т‘Р ВµР С”РЎРѓР В° Р Т‘Р В»РЎРЏ surah_name (Р С‘РЎвЂ°РЎвЂРЎвЂљРЎРЉ РЎвЂљР С•Р В»РЎРЉР С”Р С•
      // Р Р…Р В° `transliteration`). Р пїЅР ВµРЎРѓРЎвЂљРЎРЉ LIKE-search Р С—Р С• surah_name_* Р С—Р С•Р В»РЎРЏР С.
      // Р РРЎРѓР С—Р С•Р В»РЎРЉР В·РЎС“Р ВµР С SearchDao.searchByText Р ВµРЎРѓР В»Р С‘ Р Р† Р В±РЎС“Р Т‘РЎС“РЎвЂ°Р ВµР С.
      return surahDao.searchByText(q, limit: limit);
    },
    searchAyahsFn: (q, {limit = 50}) async {
      final hits = await searchDao.searchAyahsFts(q, limit: limit);
      return hits.map((hit) {
        return AyahSearchHit(
          ayahId: hit.ayahId,
          surahId: hit.surahId,
          ayahNumber: hit.ayahNumber,
          textUthmani: hit.snippet,
          textNormalized: '',
          surahNameAr: '',
        );
      }).toList(growable: false);
    },
    searchTranslationsFn: ({required query, required languageCode, int limit = 50}) async {
      final hits = await searchDao.searchTranslationsFts(
        query,
        languageCode: languageCode,
        limit: limit,
      );
      return hits.map((hit) {
        return TranslationSearchHit(
          ayahId: hit.ayahId,
          surahId: 0,
          ayahNumber: 0,
          text: hit.snippet,
          translatorName: hit.translatorId.toString(),
          surahNameAr: '',
        );
      }).toList(growable: false);
    },
    searchWordsFn: (q, {limit = 50}) async {
      final hits = await searchDao.searchWordsFts(q, limit: limit);
      return hits.map((hit) {
        return WordSearchHit(
          wordId: hit.position, // wordId == position в FTS5 hit
          surahId: 0,
          ayahNumber: 0,
          position: hit.position,
          arabic: hit.arabic,
          normalized: hit.normalized,
          translation: hit.translation,
        );
      }).toList(growable: false);
    },
    searchWordsByRootFn: (root, {limit = 20, int? excludeWordId}) async {
      return _fallbackWordsByRoot(root, limit: limit);
    },
  );
});

/// Состояние контента: загружен ли текст Корана.
class ContentReadyNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // `ref.read`, а НЕ `ref.watch`: пересборка графа бутстрапера
    // (например, каскад от `appPreferencesProvider`) не должна
    // перезапускать `build()` и затирать состояние, установленное
    // `bootstrap()`. Явная ревалидация — только через
    // `ref.invalidate(contentReadyProvider)` (см. `resetAllUserData`).
    final bootstrapper = ref.read(contentBootstrapperProvider);
    return bootstrapper.isReady();
  }

  Future<void> bootstrap() async {
    // `build()` уже выполнил isReady() — фиксируем результат до
    // сброса в loading, чтобы не делать повторные COUNT-запросы
    // на каждый warm start.
    final alreadyReady = state.valueOrNull;
    state = const AsyncValue.loading();
    try {
      final ok = await ref
          .read(contentBootstrapperProvider)
          .bootstrap(ready: alreadyReady);
      state = AsyncValue.data(ok);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      // Re-throw so the caller (e.g. _BootstrapScreen) can show a retry
      // button. Without this, errors are silently absorbed: the router
      // stays on /bootstrap and the user sees an infinite "Loading…"
      // screen with no way to recover.
      rethrow;
    }
  }
}

final contentReadyProvider =
    AsyncNotifierProvider<ContentReadyNotifier, bool>(ContentReadyNotifier.new);

/// РЇР·С‹Рє РёРЅС‚РµСЂС„РµР№СЃР° РїСЂРёР»РѕР¶РµРЅРёСЏ (ru / en / ar / null = system).
/// Fallback helpers вЂ” РёСЃРїРѕР»СЊР·СѓСЋС‚СЃСЏ searchRepositoryProvider РґР»СЏ РїРѕРёСЃРєР° РїРѕ РїРѕР»СЏРј, РЅРµ РїРѕРєСЂС‹С‚С‹Рј FTS5 (transliteration РґР»СЏ surah, root РґР»СЏ words).
/// FTS5 РїРѕРєСЂС‹РІР°РµС‚ text_uthmani (ayahs), translation text (translations), words.arabic.
/// Р”Р»СЏ surah_name_transliteration Рё words.root вЂ” РЅРµС‚ РёРЅРґРµРєСЃРѕРІ. РћС‚РґС‘Рј const [] вЂ” С„РёС‡Р°
/// Fallback helpers — использовались searchRepositoryProvider для
/// поиска по полям, не покрытым FTS5 (transliteration для surah,
/// root для words). После Sprint 2.7 `_fallbackSurahs` заменён
/// на `SurahDao.searchByText` (LIKE-fallback с strip'ом FTS5-banned
/// символов). `_fallbackWordsByRoot` пока остаётся no-op — для
/// поиска по `words.root` требуется FTS5 UNINDEXED column или
/// LIKE-fallback с нормализацией арабских букв (Hamza/Ilamed/Ya).
Future<List<WordSearchHit>> _fallbackWordsByRoot(String root, {int limit = 20}) async {
  return const <WordSearchHit>[];
}
class LanguageNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.watch(appPreferencesProvider).languageCode;
  }

  Future<void> set(String? code) async {
    state = code;
    // `appPreferencesProvider` СЃРЅРѕРІР° `Provider` (РЅРµ `Notifier`).
    // Р—Р°РїРёСЃСЊ РІ SharedPreferences вЂ” fire-and-forget, Р±РµР·
    // СѓРІРµРґРѕРјР»РµРЅРёСЏ Riverpod-РїРѕРґРїРёСЃС‡РёРєРѕРІ. Р“Р»РѕР±Р°Р»СЊРЅС‹Р№ refresh
    // `appPreferencesProvider` РЅСѓР¶РµРЅ, РїРѕС‚РѕРјСѓ С‡С‚Рѕ
    // `LanguageNotifier.state` вЂ” СЌС‚Рѕ derived value, Рё Р»СЋР±РѕР№
    // `setLanguageCode` СЃР°Рј notify'РёС‚ dependents С‡РµСЂРµР·
    // `state = AppPreferences(_prefs)` РІ `AppPreferencesNotifier`.
    await ref.read(appPreferencesProvider.notifier).setLanguageCode(code);
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, String?>(LanguageNotifier.new);
