import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/content/content_bootstrapper.dart';
import '../core/content/content_manifest.dart';
import '../core/content/quran_api.dart';
import '../core/database/app_database.dart';
import '../core/database/daos/ayah_dao.dart';
import '../core/database/daos/bookmark_dao.dart';
import '../core/database/daos/position_dao.dart';
import '../core/database/daos/surah_dao.dart';
import '../core/database/daos/translation_dao.dart';
import '../core/networking/api_client.dart';
import '../core/storage/app_preferences.dart';

/// DI-граф приложения.

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main()'),
);

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
    downloader: ref.watch(contentDownloaderProvider),
    manifestRepository: ref.watch(contentManifestRepositoryProvider),
  ),
);

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
    await ref.read(appPreferencesProvider).setLanguageCode(code);
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, String?>(LanguageNotifier.new);
