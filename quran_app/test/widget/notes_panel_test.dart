import 'package:drift/drift.dart' show OrderingTerm;
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
import 'package:quran_app/features/quran/presentation/widgets/notes_panel.dart';

/// Widget tests for [showNotesPanel] — Notes feature.
///
/// Runs in CI via 'flutter test'. On the Windows dev box 'flutter test'
/// itself can't start (a flutter_tester WebSocket bug in Flutter 3.44
/// on Win11), but the file passes 'dart analyze'.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late AppDatabase db;
  late Ayah firstAyah;

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

    firstAyah = (await (db.select(db.ayahs)
              ..where((a) => a.surahId.equals(1))
              ..orderBy([(a) => OrderingTerm.asc(a.ayahNumber)])
              ..limit(1))
            .getSingle());
  });

  tearDown(() async {
    await db.close();
  });

  Widget app() => ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Consumer(
                builder: (innerCtx, ref, _) {
                  return ElevatedButton(
                    onPressed: () => showNotesPanel(
                      context: innerCtx,
                      ref: ref,
                      ayah: firstAyah,
                    ),
                    child: const Text('open'),
                  );
                },
              ),
            ),
          ),
        ),
      );

  testWidgets('empty state shown when no notes exist', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Заметок пока нет.'), findsOneWidget);
    expect(find.text('Текст заметки…'), findsOneWidget);
  });

  testWidgets('typing + Add persists a note and flips the empty state',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'моя первая заметка');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Persisted in DB.
    final notes = await db.notesDao.watchForAyah(firstAyah.id).first;
    expect(notes, hasLength(1));
    expect(notes.first.textValue, 'моя первая заметка');
    // The text field cleared.
    expect(find.text('моя первая заметка'), findsNothing);
  });

  testWidgets('existing note is listed and deletable', (tester) async {
    await db.notesDao.addNote(ayahId: firstAyah.id, text: 'старая заметка');

    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('старая заметка'), findsOneWidget);
    expect(find.text('Заметок пока нет.'), findsNothing);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    final after = await db.notesDao.watchForAyah(firstAyah.id).first;
    expect(after, isEmpty);
  });

  testWidgets('whitespace-only text does not persist', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    final notes = await db.notesDao.watchForAyah(firstAyah.id).first;
    expect(notes, isEmpty,
        reason: 'trimmed empty input must not be saved');
  });
}
