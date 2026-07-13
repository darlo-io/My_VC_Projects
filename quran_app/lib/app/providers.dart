import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/content/content_bootstrapper.dart';
import '../core/content/content_manifest.dart';
import '../core/content/content_update_service.dart';
import '../core/content/local_seed_service.dart';
import '../core/content/quran_api.dart';
import '../core/data/bookmarks_repository.dart';
import '../core/data/learning_repository.dart';
import '../core/data/notes_repository.dart';
import '../core/data/quran_repository.dart';
import '../core/data/search_repository.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/audio_cache_dao.dart';
import '../core/database/daos/playback_sessions_dao.dart';
import '../core/database/daos/ayah_dao.dart';
import '../core/database/daos/bookmark_dao.dart';
import '../core/database/daos/learning_dao.dart';
import '../core/database/daos/notes_dao.dart';
import '../core/database/daos/position_dao.dart';
import '../core/database/daos/reciter_dao.dart';
import '../core/database/daos/surah_dao.dart';
import '../core/database/daos/translation_dao.dart';
import '../core/database/daos/word_timings_dao.dart';
import '../core/database/daos/words_dao.dart';
import '../features/reader_settings/domain/reader_display_settings.dart';
import '../core/database/models/last_read_position.dart';
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

/// DI-граф приложения.

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

/// Провайдер для [AppPreferences] — единый wrapper над
/// SharedPreferences для пользовательских настроек (тема,
/// размер шрифта, выбранный чтец и т.д.).
///
/// IMPORTANT: Это снова обычный `Provider` (не `NotifierProvider`).
/// Почему: попытки сделать `setXxx`-методы, которые **уведомляли
/// бы** подписчиков через `state = ...` или `invalidateSelf`,
/// приводили к сбросу навигации в go_router (Reader выкидывал
/// в Home при смене `readingMode`). Причина — какой-то из
/// `ref.watch(appPreferencesProvider)` в графе (LanguageNotifier,
/// cacheLimitMbProvider) пересобирался в неожиданном порядке
/// с `MaterialApp.router`, что триггерило redirect/refresh.
///
/// Сейчас `setXxx` — fire-and-forget (пишет в SharedPreferences
/// без уведомления Riverpod). UI, которому нужно **локально**
/// обновиться при изменении (например, переключение reading-mode
/// в Reader), использует `StatefulWidget.setState` и сам
/// синхронизирует с `appPreferencesProvider` через mount/refresh.
///
/// Глобально зависящие от prefs экраны (Settings, Onboarding)
/// `StateNotifierProvider` для `AppPreferences` — при любой записи
/// (`setFontSize`, `setDisplaySettings`, `setLanguageCode`, ...) все
/// `ref.watch(appPreferencesProvider)` dependents автоматически
/// получают свежий instance и ребилдятся. **Не нужен**
/// `ref.invalidate(appPreferencesProvider)` после записи — `state =`
/// триггерит notify сам.
///
/// До этого был `Provider<AppPreferences>` (без уведомлений) — запись
/// через `set*()` мутировала `SharedPreferences`, но Riverpod не знал
/// о необходимости ребилда dependents, и `readerDisplaySettingsProvider`
/// (который читает `appPreferencesProvider.displaySettings` геттер)
/// отдавал **старый** snapshot, пока кто-то явно не вызывал
/// `ref.invalidate`. См. bug report: «настройки не применяются к
/// тексту Корана ни в одном режиме».
class AppPreferencesNotifier extends StateNotifier<AppPreferences> {
  AppPreferencesNotifier(SharedPreferences prefs, this._ref)
      : _prefs = prefs,
        super(AppPreferences(prefs));
  final SharedPreferences _prefs;
  final Ref _ref;

  // `set*` методы (кроме `setDisplaySettings`) обновляют state
  // новым instance'ом — dependents (`LanguageNotifier`,
  // `reciterIdProvider`, ...) триггерят ребилд. Используется
  // редко (при смене языка / темы / чтеца), и app-wide rebuild
  // в этих сценариях безопасен (нет push-роутов на стеке).
  //
  // `setDisplaySettings` **не** триггерит state = new — это
  // локально изменяет displaySettings, и dependents (`displaySettingsProvider`)
  // подхватывают через собственный `StateNotifier`. Это нужно,
  // потому что смена displaySettings происходит на пути с push-роутом
  // (settings поверх Reader), и app-wide rebuild ломает стек
  // GoRouter (пользователь оказывается на пустом Home — см. bug).

  /// Helper: записать в SharedPreferences и триггерить rebuild
/// dependents через `state = new AppPreferences(_prefs)`.
/// Используется для всех `set*` методов, КРОМЕ тех, которые
/// не должны вызывать app-wide rebuild (см. [setReadingMode]
/// и [setDisplaySettings]).
Future<void> _setAndNotify(Future<void> Function() write) async {
  await write();
  state = AppPreferences(_prefs);
}

Future<void> setDisplaySettings(ReaderDisplaySettings s) async {
  // Без `state = ...` — НЕ notify dependents. Отдельный
  // `displaySettingsProvider` сам notify'ит свои dependents
  // (Reader, Preview) сразу после записи.
  await state.setDisplaySettings(s);
  _ref.read(displaySettingsProvider.notifier).refresh();
}

Future<void> setFontSize(double v) =>
    _setAndNotify(() => state.setFontSize(v));

Future<void> setLanguageCode(String? code) =>
    _setAndNotify(() => state.setLanguageCode(code));

  Future<void> setReadingMode(String mode) async {
    // **НЕ** триггерим `state = ...` — это вызвало бы app-wide
    // rebuild, который ломает навигацию GoRouter (пользователь
    // оказывается на пустом Home). Локальный `setState` в
    // `ReaderScreenState` (через `_readingMode`) уже обновляет
    // UI. В SharedPreferences запись нужна для сохранения
    // между сессиями. На следующем mount / refresh Reader
    // прочитает свежее значение через
    // `appPreferencesProvider.readingMode` (старт сессии).
    await state.setReadingMode(mode);
  }

  // Custom DNS settings — НЕ триггерим app-wide rebuild
  // автоматически; пользователь явно нажимает Save в Settings,
  // и `dioProvider` сделает `_ref.invalidate(...)` явно через
  // отдельный путь, чтобы UI не пересобирался.

  /// Включает/выключает [DnsAwareInterceptor]. См. `appPreferencesProvider.useCustomDns`.
  ///
  /// ⚠️ НЕ делаем `state = AppPreferences(_prefs)` — это app-wide
  /// rebuild, который ломает GoRouter-stack (см. round-7/8 hotfix).
  /// Вместо этого инкрементим [dnsSettingsVersionProvider] —
  /// `dioProvider` слушает его и переcоздаёт `Dio` точечно, без
  /// каскада на `apiClientProvider` / `audioCacheProvider` /
  /// `audioPlayerControllerProvider`.
  Future<void> setUseCustomDns(bool v) async {
    debugPrint('[DNS_NOTIFIER] setUseCustomDns start v=$v');
    await state.setUseCustomDns(v);
    debugPrint('[DNS_NOTIFIER] state.setUseCustomDns ok');
    _ref.read(dnsSettingsVersionProvider.notifier).update((s) => s + 1);
    debugPrint('[DNS_NOTIFIER] dnsSettingsVersionProvider updated to '
        '${_ref.read(dnsSettingsVersionProvider) + 0}');
  }

  /// Устанавливает DoH-endpoint URL. При включении
  /// [setUseCustomDns] `true` все HTTP-запросы идут через него.
  Future<void> setCustomDohUrl(String? url) async {
    debugPrint('[DNS_NOTIFIER] setCustomDohUrl start url=$url');
    await state.setCustomDohUrl(url);
    debugPrint('[DNS_NOTIFIER] state.setCustomDohUrl ok');
    _ref.read(dnsSettingsVersionProvider.notifier).update((s) => s + 1);
  }

Future<void> setTranslationLang(String lang) =>
    _setAndNotify(() => state.setTranslationLang(lang));

Future<void> setReciterId(String id) async {
  // Записываем напрямую в SharedPreferences **БЕЗ** `state = AppPreferences(...)`
  // — потому что app-wide rebuild ломает GoRouter-stack
  // (пользователь оказывается на пустом Home — см. round-7
  // hotfix report). Dependents, которым нужен свежий `reciterId`,
  // читают его напрямую через `appPreferencesProvider.reciterId`
  // (геттер), который `SharedPreferences` синхронизирует
  // синхронно.
  await state.setReciterId(id);
  // Без `state = AppPreferences(_prefs)`. См. комментарий в
  // setReadingMode (line 126) — аналогичный паттерн для
  // избежания app-wide rebuild на пользовательских actions
  // (выбор ректора, переключение языка чтения).
}

Future<void> setThemeMode(String mode) =>
    _setAndNotify(() => state.setThemeMode(mode));

Future<void> setFirstLaunchDone(bool v) =>
    _setAndNotify(() => state.setFirstLaunchDone(v));

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

/// Bump-counter, который `setUseCustomDns` / `setCustomDohUrl`
/// в `AppPreferencesNotifier` инкрементят. `dnsSettingsProvider`
/// watch'ит этот counter — инкремент переcоздаёт его, и при
/// новом вычислении мы читаем свежее значение из
/// `appPreferencesProvider` БЕЗ `state = AppPreferences(_prefs)`
/// (т.е. без app-wide rebuild).
///
/// В обычном lifecycle (без пользовательского изменения DNS)
/// counter не меняется → dependents кешируются.
final dnsSettingsVersionProvider = StateProvider<int>((_) => 0);

/// Изолированный sub-selector для DNS-настроек. Существует
/// чтобы `dioProvider` мог watch'ить **только** `useCustomDns`/
/// и `customDohUrl` (а не весь `appPreferencesProvider` целиком)
/// — иначе любое изменение `reciterId` / `fontSize` /
/// `themeMode` приводило бы к переcозданию `Dio` и invalidate
/// каскада dependents (включая `audioPlayerControllerProvider`,
/// чей `dispose()` мог ронять Drift — см. round-8 hotfix).
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

/// `Dio`-клиент для **JSON-API** (Quran API, content-updates, search).
/// Реактивно пересоздаётся **только** при изменении DNS-настроек
/// (см. [dnsSettingsProvider]).
///
/// ВАЖНО: `audioCacheProvider` НЕ зависит от этого провайдера —
/// см. [audioDioProvider] и [audioCacheProvider]. Иначе cascade
/// invalidate на смене DNS уничтожал бы `audioPlayerControllerProvider`
/// (StateNotifier) и его Drift-операции в `dispose()` (см.
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
    // Резолвер живёт на отдельном Dio-инстансе, чтобы не
    // закольцеваться (если бы он шёл через `dioProvider`,
    // тот же DnsAwareAdapter бы перехватил наш собственный
    // запрос и зарезолвил бы `1.1.1.1` через `1.1.1.1` —
    // бесконечная рекурсия).
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

/// Обёрнутый в [ApiClient] для удобного JSON API.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(dio: ref.watch(dioProvider)),
);

/// **Статический** `Dio` для аудио-кеша и плеера. **НЕ зависит**
/// ни от `dnsSettingsProvider`, ни от `appPreferencesProvider` —
/// чтобы invalidate cascade на смене DNS **никогда** не доходил
/// до `audioCacheProvider` / `audioPlayerControllerProvider`
/// (StateNotifier, чей `dispose()` может ронять Drift — см.
/// round-9 hotfix).
///
/// **Компромисс**: при включённом Custom DNS аудио-загрузки идут
/// через системный DNS (тот же captive DNS, что и до этого
/// фикса). Это значит, что DoH на audio-кеш не работает. JSON
/// API при этом ходит через `dioProvider` → DnsAwareAdapter.
/// Это разумный trade-off: cache-miss-страдает меньше, чем
/// крашащийся UI на каждом клике по Settings.
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

final quranApiProvider = Provider<QuranApi>(
  (ref) => QuranApi(ref.watch(apiClientProvider)),
);

/// Асинхронная загрузка перевода текущего аята на языке приложения.
/// Возвращает `null` если перевода нет в БД — тогда в [_AyahPanel]
/// мелкий сабтайтл просто не показывается.
final ayahTranslationProvider =
    FutureProvider.family<String?, SurahAyahRef>(
  (ref, key) async {
    // Берём язык из [AppPreferences] — он синхронизирован с локалью
    // приложения через [LocaleSettingsNotifier]. `WidgetsBinding` тут
    // не сработает — нам нужен BuildContext, а в провайдере его нет.
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

/// **Изолированный** StateNotifier для display-настроек Reader'а.
///
/// `appPreferencesProvider` — глобальный, от него зависят десятки
/// провайдеров (`LanguageNotifier`, `reciterIdProvider`, ...). При
/// его обновлении (`state = new AppPreferences`) Riverpod делает
/// app-wide rebuild, что в race с `context.pop()` ломает стек
/// GoRouter — пользователь оказывается на пустом Home (см. bug
/// report от 16.06.2026: «настройки не применяются к тексту Корана»).
///
/// `displaySettingsProvider` — **локальный** StateNotifier с
/// собственным `state`. Запись `set*` обновляет только его
/// dependents (`Reader`, `PreviewAyah`), без каскада на остальной
/// app. Поэтому `setDisplaySettings` из settings-экрана безопасно
/// триггерит ребилд `Reader`'а (он на стеке ниже) и не ломает
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
    // `set` в `appPreferencesProvider` (через `setDisplaySettings`)
    // НЕ вызывает `state = new AppPreferences(...)` — только пишет
    // в SharedPreferences и кладёт новый snapshot в `state`
    // (через `refresh()`). Здесь мы делаем **локальное** обновление
    // — `state = s` — что триггерит ребилд только dependents
    // `displaySettingsProvider` (Reader, Preview).
    await _ref.read(appPreferencesProvider.notifier).setDisplaySettings(s);
    state = s;
  }

  /// Принудительный refresh — вызывается из `AppPreferencesNotifier.setDisplaySettings`
  /// если что-то (например, `clearAll`) изменило displaySettings в
  /// SharedPreferences извне нашего прямого flow.
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

/// Снимок display-настроек Reader'а (fontSize, lineHeight,
/// themeVariant, ...). Источник истины — **`displaySettingsProvider`**
/// (изолированный StateNotifier), а НЕ `appPreferencesProvider` —
/// чтобы избежать app-wide rebuild при записи.
///
/// Запись из `appPreferencesProvider.setDisplaySettings` теперь
/// делает **локальный** `state =` в `displaySettingsProvider`,
/// и только dependents (`Reader`, `Preview`) ребилдятся.
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
/// session on every watch — the screen calls
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
final audioCacheDaoProvider = Provider<AudioCacheDao>(
  (ref) => ref.watch(appDatabaseProvider).audioCacheDao,
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

final recitersRepositoryProvider = Provider<RecitersRepository>(
  (ref) => RecitersRepository(ref.watch(reciterDaoProvider)),
);

/// Фоновый воркер синхронизации mp3quran-ректоров. Singleton, потому
/// что у него есть in-memory `ValueNotifier<RecitersSyncState>` — при
/// каждом [ForceRefresh]-стиле инвалидировании состояние терялось бы.
///
/// `ref.watch(recitersSyncServiceProvider)` подписан UI, который
/// может показать «синхронизация идёт» / «последний sync был X».
final recitersSyncServiceProvider = Provider<RecitersSyncService>((ref) {
  return RecitersSyncService(ref.watch(recitersRepositoryProvider));
});

final audioCacheProvider = Provider<AudioCache>(
  (ref) => AudioCache(
    // `audioDioProvider` (НЕ `apiClientProvider`) — это разрывает
    // cascade invalidate до `audioPlayerControllerProvider`
    // (StateNotifier, чей `dispose()` мог ронять Drift — см.
    // round-9 hotfix). При смене DNS DoH автоматически
    // подменяет `httpClientAdapter` через [DnsAwareAdapter].
    dio: ref.watch(audioDioProvider),
    dao: ref.watch(audioCacheDaoProvider),
    // `prefs` нужен для LRU-eviction в play-path. Provider
    // инжектируется, чтобы избежать прямой зависимости от
    // SharedPreferences в audio-подсистеме.
    prefs: ref.watch(appPreferencesProvider),
  ),
);

/// Стрим ID ректоров, у которых скачаны все 114 MP3.
/// Используется в reciter picker'е для иконки «полностью загружен».
final fullyCachedRecitersProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(audioCacheProvider).watchFullyCachedReciters(),
);

/// Контроллер фоновой загрузки всех MP3 для ректора (prefetch all).
/// Singleton, один слот — см. [ReciterDownloadController].
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

/// Ключ для [ayahTextProvider] — пара (surahId, ayahNumber).
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

/// Ключ для [_surahByIdProvider] — просто ID суры (для FutureProvider.family).
class SurahIdKey {
  const SurahIdKey(this.id);
  final int id;
  @override
  bool operator ==(Object other) =>
      other is SurahIdKey && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

/// Provider для асинхронной загрузки суры по id. Используется
/// [_SurahAyahSelectors] для получения актуального `ayahCount` —
/// до вызова `playSurah()` (когда `state.surah` ещё пустой).
final surahByIdProvider = FutureProvider.family<Surah?, SurahIdKey>(
  (ref, key) => ref.watch(surahDaoProvider).getById(key.id),
);

/// Асинхронная загрузка аята из БД (Uthmani-текст) для отображения в
/// [_AyahPanel]. Использует FutureProvider.family — Riverpod
/// автоматически дедуплицирует одинаковые ключи, поэтому при
/// смене currentAyah не происходит лишних запросов.
final ayahTextProvider = FutureProvider.family<Ayah?, SurahAyahRef>(
  (ref, key) async {
    final dao = ref.watch(ayahDaoProvider);
    return dao.getBySurahAndNumber(key.surahId, key.ayahNumber);
  },
);

/// Поток общего размера аудио-кеша в байтах (для UI).
final cacheTotalBytesProvider = StreamProvider<int>((ref) {
  return ref.watch(audioCacheProvider).watchTotalBytes();
});

/// Текущий лимит кеша в мегабайтах.
final cacheLimitMbProvider = StateProvider<int>((ref) {
  return ref.watch(appPreferencesProvider).cacheLimitMb;
});

final contentDownloaderProvider = Provider<ContentDownloader>(
  (ref) => ContentDownloader(ref.watch(quranApiProvider)),
);

final contentUpdateServiceProvider = Provider<ContentUpdateService>((ref) {
  // Берём `appVersion` из PackageInfo (через `appVersionProvider`),
  // иначе — fallback из `pubspec.yaml: version` (1.0.0+1 →
  // strip build → '1.0.0'). `appVersionProvider` обновляется в
  // `main.dart` через `PackageInfo.fromPlatform()` после старта
  // приложения; до этого момента используется fallback.
  final pkg = ref.watch(appVersionProvider);
  return ContentUpdateService(
    api: ref.watch(quranApiProvider),
    manifestRepository: ref.watch(contentManifestRepositoryProvider),
    appVersion: pkg ?? '1.0.0',
  );
});

/// Текущая версия приложения (`pubspec.yaml: version`).
/// Инициализируется в `main.dart` через `PackageInfo.fromPlatform()`.
/// Используется для [min_app_version] проверки в
/// [ContentUpdateService].
final appVersionProvider = StateProvider<String?>((ref) => null);

final contentManifestRepositoryProvider =
    Provider<ContentManifestRepository>(
  (ref) => ContentManifestRepository(ref.watch(appPreferencesProvider)),
);

final contentBootstrapperProvider = Provider<ContentBootstrapper>(
  (ref) {
    final bootstrapper = ContentBootstrapper(
      db: ref.watch(appDatabaseProvider),
      surahDao: ref.watch(surahDaoProvider),
      ayahDao: ref.watch(ayahDaoProvider),
      translationDao: ref.watch(translationDaoProvider),
      wordsDao: ref.watch(wordsDaoProvider),
      wordTimingsDao: ref.watch(wordTimingsDaoProvider),
      downloader: ref.watch(contentDownloaderProvider),
      manifestRepository: ref.watch(contentManifestRepositoryProvider),
      recitersRepository: ref.watch(recitersRepositoryProvider),
      localSeed: LocalSeedService(),
    );
    // Опциональная прокрутка `contentUpdateService` через тот же
    // `ref`. Позволяет `_fetchFromNetworkInBackground` вызвать
    // `checkAndApply()` без жёсткой DI-зависимости.
    final updateService = ref.watch(contentUpdateServiceProvider);
    bootstrapper.contentUpdateService = updateService;
    // Фоновая синхронизация списка чтецов с mp3quran.net —
    // [RecitersSyncService.maybeSync] в фоне после `ensureSeeded`.
    bootstrapper.recitersSyncService =
        ref.watch(recitersSyncServiceProvider);
    return bootstrapper;
  },
);

/// Полный сброс пользователя: wipes user-data tables +
/// очищает аудио-кеш + сбрасывает SharedPreferences (кроме
/// контент-манифеста, который восстановится на следующем
/// bootstrap). Используется из SettingsScreen «Reset all data».
/// После вызова стоит перезапустить `contentReadyProvider`,
/// чтобы UI заметил изменения.
///
/// Принимает [WidgetRef] из Riverpod — на текущий момент
/// единственный вызывающий (SettingsScreen) живёт в widget tree,
/// и тащить `ProviderScope.containerOf(context)` туда было бы
/// лишним шумом. При переносе логики в non-widget-контекст
/// достаточно будет сделать обёртку, принимающую [Ref].
Future<void> resetAllUserData(WidgetRef ref) async {
  await ref.read(appDatabaseProvider).wipeUserData();
  await ref.read(audioCacheProvider).clearAll();
  // `AppPreferences.clearAll` стирает `app.*` / `reader.*` / `audio.*`
  // ключи в SharedPreferences (включая `app.firstLaunchDone`).
  // Без этого `isFirstLaunchDone` остаётся `true` после reset и
  // пользователь НЕ попадает на /onboarding, а сразу на / —
  // см. `app_router.dart:_run()`. `clearAll` теперь сам
  // уведомляет dependents через `state = AppPreferences(_prefs)`
  // в `AppPreferencesNotifier`.
  await ref.read(appPreferencesProvider.notifier).clearAll();
  // Пересоздаём готовое состояние — теперь isReady() == true
  // (контент есть), но last_position == null, закладки пустые и т.д.
  ref.invalidate(contentReadyProvider);
}

// ----- Repositories (ARCHITECTURE §4) -----
// UI читает только эти Provider'ы, не DAO напрямую.

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
  // SearchRepository принимает функции вместо DAOs, чтобы не тянуть
  // циклический импорт (см. комментарий в SearchRepository). Здесь
  // мы биндим DAO-методы в plain-функции через tearoff (`dao.method`)
  // — `this` фиксируется автоматически.
  final surahDao = ref.watch(surahDaoProvider);
  final ayahDao = ref.watch(ayahDaoProvider);
  final translationDao = ref.watch(translationDaoProvider);
  final wordsDao = ref.watch(wordsDaoProvider);
  return SearchRepository(
    searchSurahsFn: surahDao.searchByText,
    searchAyahsFn: ayahDao.searchByText,
    searchTranslationsFn: translationDao.search,
    searchWordsFn: wordsDao.search,
    searchWordsByRootFn: wordsDao.searchByRoot,
  );
});

/// Состояние контента: загружен ли текст Корана.
class ContentReadyNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final bootstrapper = ref.watch(contentBootstrapperProvider);
    return bootstrapper.isReady();
  }

  Future<void> bootstrap() async {
    state = const AsyncValue.loading();
    try {
      final ok = await ref.read(contentBootstrapperProvider).bootstrap();
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

/// Язык интерфейса приложения (ru / en / ar / null = system).
class LanguageNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.watch(appPreferencesProvider).languageCode;
  }

  Future<void> set(String? code) async {
    state = code;
    // `appPreferencesProvider` снова `Provider` (не `Notifier`).
    // Запись в SharedPreferences — fire-and-forget, без
    // уведомления Riverpod-подписчиков. Глобальный refresh
    // `appPreferencesProvider` нужен, потому что
    // `LanguageNotifier.state` — это derived value, и любой
    // `setLanguageCode` сам notify'ит dependents через
    // `state = AppPreferences(_prefs)` в `AppPreferencesNotifier`.
    await ref.read(appPreferencesProvider.notifier).setLanguageCode(code);
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, String?>(LanguageNotifier.new);
