import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/content/content_bootstrapper.dart';
import '../core/content/content_manifest.dart';
import '../core/content/local_seed_service.dart';
import '../core/content/quran_api.dart';
import '../core/data/bookmarks_repository.dart';
import '../core/data/learning_repository.dart';
import '../core/data/notes_repository.dart';
import '../core/data/quran_repository.dart';
import '../core/data/search_repository.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/audio_cache_dao.dart';
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
import '../core/database/models/last_read_position.dart';
import '../features/audio/data/quran_audio_handler.dart';
import '../features/test/data/quiz_service.dart';
import '../features/test/data/quiz_session.dart';
import '../core/networking/api_client.dart';
import '../core/storage/app_preferences.dart';
import '../features/audio/data/audio_cache.dart';
import '../features/audio/data/audio_player_controller.dart';
import '../features/audio/data/reciters_repository.dart';

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
/// делают `ref.refresh(appPreferencesProvider)` после записи —
/// см. `LanguageNotifier.set` / `setTranslationLang` в Settings.
final appPreferencesProvider = Provider<AppPreferences>(
  (ref) => AppPreferences(ref.watch(sharedPreferencesProvider)),
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final quranApiProvider = Provider<QuranApi>(
  (ref) => QuranApi(ref.watch(apiClientProvider)),
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

final audioCacheProvider = Provider<AudioCache>(
  (ref) => AudioCache(
    dio: ref.watch(apiClientProvider).raw,
    dao: ref.watch(audioCacheDaoProvider),
  ),
);

final audioPlayerControllerProvider =
    StateNotifierProvider<AudioPlayerController, AudioPlayerState>(
  (ref) => AudioPlayerController(
    cache: ref.watch(audioCacheProvider),
    reciters: ref.watch(recitersRepositoryProvider),
    surahDao: ref.watch(surahDaoProvider),
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

final contentManifestRepositoryProvider =
    Provider<ContentManifestRepository>(
  (ref) => ContentManifestRepository(ref.watch(appPreferencesProvider)),
);

final contentBootstrapperProvider = Provider<ContentBootstrapper>(
  (ref) => ContentBootstrapper(
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
  ),
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
  // `clearAll` стирает префы, потом notifier инвалидируется →
  // все подписчики (`ref.watch(appPreferencesProvider)`) видят
  // пустые значения. Затем `contentReadyProvider` тоже сбрасывается
  // — комбинация этих двух эффектов перекидывает пользователя на
  // /bootstrap, откуда он попадёт на /onboarding.
  ref.invalidate(appPreferencesProvider);
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
    // widget, делающий `ref.watch(appPreferencesProvider)`
    // (например, Settings или Onboarding), должен увидеть
    // новое значение languageCode.
    await ref.read(appPreferencesProvider).setLanguageCode(code);
    ref.invalidate(appPreferencesProvider);
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, String?>(LanguageNotifier.new);
