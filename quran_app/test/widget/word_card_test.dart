import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/app/providers.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/storage/app_preferences.dart';
import 'package:quran_app/core/content/content_manifest.dart';
import 'package:quran_app/core/content/content_bootstrapper.dart';
import 'package:quran_app/core/content/local_seed_service.dart';
import 'package:quran_app/core/content/quran_api.dart';
import 'package:quran_app/core/networking/api_client.dart';
import 'package:quran_app/features/audio/data/reciters_repository.dart';
import 'package:quran_app/features/learning/presentation/word_card.dart';

/// Widget tests for [showWordCard].
///
/// Runs in CI via 'flutter test'. On the Windows dev box 'flutter test'
/// itself can't start (a flutter_tester WebSocket bug in Flutter 3.44
/// on Win11), but the file passes 'dart analyze'.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late AppDatabase db;
  late Word sampleWord;

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    final appPrefs = AppPreferences(prefs);

    db = AppDatabase.forTesting(NativeDatabase.memory());
    final bootstrapper = ContentBootstrapper(
      db: db,
      surahDao: db.surahDao,
      ayahDao: db.ayahDao,
      translationDao: db.translationDao,
      wordsDao: db.wordsDao,
      wordTimingsDao: db.wordTimingsDao,
      downloader: ContentDownloader(QuranApi(ApiClient())),
      manifestRepository: ContentManifestRepository(appPrefs),
      recitersRepository: RecitersRepository(db.reciterDao),
      localSeed: LocalSeedService(),
    );
    await bootstrapper.bootstrap();

    // Al-Fatiha's first word is a real seed entry.
    sampleWord = (await (db.select(db.words)
              ..where((w) => w.ayahId.equals(1))
              ..orderBy([(w) => OrderingTerm.asc(w.position)])
              ..limit(1))
            .getSingle());
  });

  tearDown(() async {
    await db.close();
  });

  Future<Word> fetchWord() => (db.select(db.words)
        ..where((w) => w.id.equals(sampleWord.id))
        ..limit(1))
      .getSingle();

  /// Wraps a [Word] in a [WidgetRef]-aware button so we can call
  /// [showWordCard] (which requires both `context` and `ref`).
  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Consumer(
              builder: (innerCtx, ref, _) {
                return ElevatedButton(
                  onPressed: () => showWordCard(
                    context: innerCtx,
                    ref: ref,
                    word: sampleWord,
                  ),
                  child: child,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('showWordCard opens a modal bottom sheet with the Arabic word',
      (tester) async {
    sampleWord = await fetchWord();
    await tester.pumpWidget(const Text('open'));
    await tester.pumpWidget(wrap(const Text('open')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(ModalBottomSheetRoute), findsOneWidget);
    expect(find.text(sampleWord.arabic), findsOneWidget);
    expect(find.text('Добавить в словарь'), findsOneWidget,
        reason: 'fresh word is not in vocabulary yet');
    expect(find.text('В словаре'), findsNothing);
  });

  testWidgets('"В словаре" appears for words already in vocabulary',
      (tester) async {
    sampleWord = await fetchWord();
    await db.learningDao.addWord(sampleWord.id);
    await tester.pumpWidget(wrap(const Text('open')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('В словаре'), findsOneWidget);
    expect(find.text('Добавить в словарь'), findsNothing);
  });

  testWidgets('tapping Add persists the word and flips the UI',
      (tester) async {
    sampleWord = await fetchWord();
    await tester.pumpWidget(wrap(const Text('open')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Добавить в словарь'));
    await tester.pumpAndSettle();

    final ids = await db.learningDao.watchVocabularyIds().first;
    expect(ids, contains(sampleWord.id));
    expect(find.text('В словаре'), findsOneWidget);
  });
}
