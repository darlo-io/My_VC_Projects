import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/core/content/content_bootstrapper.dart';
import 'package:quran_app/core/content/content_manifest.dart';
import 'package:quran_app/core/content/local_seed_service.dart';
import 'package:quran_app/core/content/quran_api.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/networking/api_client.dart';
import 'package:quran_app/core/storage/app_preferences.dart';
import 'package:quran_app/features/audio/data/reciters_repository.dart';

/// End-to-end integration test for [ContentBootstrapper].
///
/// This is the test that would have caught both bootstrap bugs that
/// shipped in commit `2f7e271`:
///   - The `null is not a subtype of int` in `_explodeAyahs` (now fixed).
///   - The `Translators` table missing a primary key (now fixed).
///
/// Runs in CI via `flutter test`. On the developer's Windows machine
/// `flutter test` itself doesn't start (a flutter_tester WebSocket bug),
/// but the test file compiles under `dart analyze`.
///
/// On setup:
///   - `AppDatabase` is opened with `NativeDatabase.memory()` — an
///     in-memory SQLite, no filesystem involvement.
///   - `SharedPreferences.setMockInitialValues({})` lets `AppPreferences`
///     run without a real platform channel.
///   - `ContentDownloader` is wired but never called: the bootstrap
///     path under test is the offline-local-seed path; the network
///     fetch is `unawaited` and only runs after the assertion-relevant
///     work has completed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late AppDatabase db;
  late ContentBootstrapper bootstrapper;

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    final appPrefs = AppPreferences(prefs);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    final recitersRepo = RecitersRepository(db.reciterDao);

    bootstrapper = ContentBootstrapper(
      db: db,
      surahDao: db.surahDao,
      ayahDao: db.ayahDao,
      translationDao: db.translationDao,
      wordsDao: db.wordsDao,
      wordTimingsDao: db.wordTimingsDao,
      // downloader is never called on the local-seed path; constructing
      // it requires a QuranApi instance but its downloadAll() is never
      // invoked in the assertion scope. We pass a real (but unused)
      // ApiClient — none of its methods are reached.
      downloader: ContentDownloader(QuranApi(ApiClient())),
      manifestRepository: ContentManifestRepository(appPrefs),
      recitersRepository: recitersRepo,
      localSeed: LocalSeedService(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('isReady returns false on a fresh in-memory DB', () async {
    expect(await bootstrapper.isReady(), isFalse,
        reason: 'fresh DB has no surahs/ayahs yet');
  });

  test('bootstrap() populates all canonical tables from local seed',
      () async {
    final ok = await bootstrapper.bootstrap();
    expect(ok, isTrue);

    expect(await db.surahDao.count(), 114);
    expect(await db.ayahDao.count(), 6236);
    expect(await db.reciterDao.count(), 8,
        reason: 'kDefaultReciters is 8');

    // translations/translators use raw SQL — no DAO count() method.
    final translationCount = await db.customSelect(
      'SELECT COUNT(*) AS c FROM translations',
      readsFrom: {db.translations},
    ).getSingle();
    expect(translationCount.read<int>('c'), greaterThan(12000));

    final translatorCount = await db.customSelect(
      'SELECT COUNT(*) AS c FROM translators',
      readsFrom: {db.translators},
    ).getSingle();
    expect(translatorCount.read<int>('c'), 2,
        reason: 'ru.kuliev + en.sahih');
  });

  test('after bootstrap, isReady() returns true', () async {
    expect(await bootstrapper.isReady(), isFalse);
    await bootstrapper.bootstrap();
    expect(await bootstrapper.isReady(), isTrue);
  });

  test('a second bootstrap() call is a no-op (idempotent at the DB level)',
      () async {
    await bootstrapper.bootstrap();
    final firstSurahCount = await db.surahDao.count();
    final firstAyahCount = await db.ayahDao.count();

    // Second call should detect isReady()=true and skip the inserts.
    final ok2 = await bootstrapper.bootstrap();
    expect(ok2, isTrue);
    expect(await db.surahDao.count(), firstSurahCount,
        reason: 'surah count must not change on a re-bootstrap');
    expect(await db.ayahDao.count(), firstAyahCount,
        reason: 'ayah count must not change on a re-bootstrap');
  });

  test('ayahs are queryable by surah after bootstrap', () async {
    await bootstrapper.bootstrap();
    final alFatihaAyahs = await db.ayahDao.watchBySurah(1).first;
    expect(alFatihaAyahs, hasLength(7),
        reason: 'Al-Fatiha has 7 ayahs');
    final alBaqarahAyahs = await db.ayahDao.watchBySurah(2).first;
    expect(alBaqarahAyahs, hasLength(286),
        reason: 'Al-Baqarah has 286 ayahs');
  });

  test('reciters table is seeded with the canonical 8 reciters', () async {
    await bootstrapper.bootstrap();
    final reciters = await db.select(db.reciters).get();
    final ids = reciters.map((r) => r.id).toSet();
    expect(ids, containsAll(['ar.alafasy', 'ar.abdulbasitmurattal',
        'ar.husary', 'ar.minshawi']));
  });

  test('Al-Fatiha words + word timings are seeded for ar.alafasy', () async {
    await bootstrapper.bootstrap();
    final wordCount = await db.customSelect(
      'SELECT COUNT(*) AS c FROM words WHERE ayah_id = 1',
      readsFrom: {db.words},
    ).getSingle();
    expect(wordCount.read<int>('c'), greaterThan(0),
        reason: 'Al-Fatiha must have words seeded');

    final timingCount = await db.customSelect(
      'SELECT COUNT(*) AS c FROM word_timings WHERE reciter_id = ?',
      variables: [Variable.withString('ar.alafasy')],
      readsFrom: {db.wordTimings},
    ).getSingle();
    expect(timingCount.read<int>('c'), greaterThan(0),
        reason: 'Al-Fatiha word timings for ar.alafasy must be seeded');
  });
}
