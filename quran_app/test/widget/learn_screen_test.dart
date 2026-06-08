import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/app/providers.dart';
import 'package:quran_app/core/content/content_bootstrapper.dart';
import 'package:quran_app/core/content/content_manifest.dart';
import 'package:quran_app/core/content/local_seed_service.dart';
import 'package:quran_app/core/content/quran_api.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/networking/api_client.dart';
import 'package:quran_app/core/storage/app_preferences.dart';
import 'package:quran_app/features/audio/data/reciters_repository.dart';
import 'package:quran_app/features/learning/presentation/learn_screen.dart';

/// Widget tests for [LearnScreen] — Learn feature step 3/3.
///
/// Runs in CI via 'flutter test'. On the Windows dev box 'flutter test'
/// itself can't start (a flutter_tester WebSocket bug in Flutter 3.44
/// on Win11), but the file passes 'dart analyze'.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late AppDatabase db;

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
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addFirstWord() async {
    final firstId = (await db.customSelect(
      'SELECT id FROM words WHERE ayah_id = 1 ORDER BY id ASC LIMIT 1',
      readsFrom: {db.words},
    ).getSingle()).read<int>('id');
    await db.learningDao.addWord(firstId);
    return firstId;
  }

  Widget app() => ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: LearnScreen()),
      );

  testWidgets('empty-state shows "Все слова выучены" when vocabulary is empty',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Все слова выучены'), findsOneWidget);
    expect(find.text('Добавить в словарь'), findsNothing);
  });

  testWidgets('review card shows Arabic word + 6 quality buttons',
      (tester) async {
    final wordId = await addFirstWord();
    final word = await (db.select(db.words)..where((w) => w.id.equals(wordId)))
        .getSingle();

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Все слова выучены'), findsNothing);
    expect(find.text(word.arabic), findsOneWidget);
    // 6 quality buttons (0..5), each labeled in Russian.
    expect(find.text('Не помню'), findsOneWidget);
    expect(find.text('С трудом'), findsOneWidget);
    expect(find.text('С усилием'), findsOneWidget);
    expect(find.text('Помню'), findsOneWidget);
    expect(find.text('Хорошо'), findsOneWidget);
    expect(find.text('Отлично'), findsOneWidget);
  });

  testWidgets('quality 5 advances: word reviewed, due list shrinks',
      (tester) async {
    await addFirstWord();

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Отлично'), findsOneWidget);
    await tester.tap(find.text('Отлично'));
    await tester.pumpAndSettle();

    // After a perfect review, the word's nextReviewAt moves forward
    // past 'now' — due list must no longer contain it.
    final due = await db.learningDao.watchDue().first;
    expect(due, isEmpty,
        reason: 'one q=5 review pushes the word past the due horizon');

    // The empty state appears.
    expect(find.text('Все слова выучены'), findsOneWidget);
  });

  testWidgets('quality 0 (lapse) keeps the word in the due list',
      (tester) async {
    final wordId = await addFirstWord();

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Не помню'));
    await tester.pumpAndSettle();

    final due = await db.learningDao.watchDue().first;
    expect(due, hasLength(1),
        reason: 'q=0 resets interval to 1 day, so the word stays due');
    expect(due.first.word.id, wordId);
  });
}
