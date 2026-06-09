import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/database/daos/bookmark_dao.dart';
import 'package:quran_app/core/database/daos/notes_dao.dart';
import 'package:quran_app/core/database/daos/surah_dao.dart';

/// Combined unit tests for the small per-ayah DAO trio:
/// [BookmarkDao], [NotesDao], and [SurahDao].
///
/// Uses an in-memory [NativeDatabase] so the suite is hermetic
/// and fast. Runs under `flutter test`; on Windows hosts the
/// `flutter_tester` WebSocket bug may still crash the runner,
/// so run on Linux/macOS or in CI.
void main() {
  late AppDatabase db;
  late BookmarkDao bookmarkDao;
  late NotesDao notesDao;
  late SurahDao surahDao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    bookmarkDao = db.bookmarkDao;
    notesDao = db.notesDao;
    surahDao = db.surahDao;
  });

  tearDown(() async {
    await db.close();
  });

  /// Seed Al-Fatiha (7 ayahs) + a second surah for cross-surah
  /// tests. The fixture matches what real seed data looks like
  /// (id = 1..114 for surahs, id = 1..6236 for ayahs).
  Future<void> seedFixture() async {
    for (final surahId in [1, 2]) {
      await db.into(db.surahs).insert(
            SurahsCompanion.insert(
              id: Value(surahId),
              nameAr: surahId == 1 ? 'الفاتحة' : 'البقرة',
              nameEn: surahId == 1 ? 'The Opening' : 'The Cow',
              nameTransliteration: surahId == 1 ? 'Al-Fatiha' : 'Al-Baqara',
              revelationType: 'Meccan',
              ayahCount: surahId == 1 ? 7 : 286,
              orderInMushaf: surahId,
            ),
          );
    }
    // 10 ayahs of Al-Fatiha.
    for (var i = 1; i <= 7; i++) {
      await db.into(db.ayahs).insert(
            AyahsCompanion.insert(
              id: Value(i),
              surahId: 1,
              ayahNumber: i,
              textUthmani: 'ayah $i',
              textNormalized: 'ayah $i',
            ),
          );
    }
    // 3 ayahs of Al-Baqara.
    for (var i = 1; i <= 3; i++) {
      await db.into(db.ayahs).insert(
            AyahsCompanion.insert(
              id: Value(7 + i),
              surahId: 2,
              ayahNumber: i,
              textUthmani: 'baqara $i',
              textNormalized: 'baqara $i',
            ),
          );
    }
  }

  // ──────────────────────── BookmarkDao ────────────────────────

  group('BookmarkDao', () {
    test('insertBookmark is idempotent on (ayahId)', () async {
      await seedFixture();
      // First insert succeeds; second insert on the same
      // (surah_id, ayah_number) — the underlying table has no
      // UNIQUE on ayahId, but `insertOrIgnore` is used so a
      // repeat is a silent no-op.
      final first = await bookmarkDao.insertBookmark(
        BookmarksCompanion.insert(
          surahId: 1,
          ayahId: 1,
          ayahNumber: 1,
        ),
      );
      final second = await bookmarkDao.insertBookmark(
        BookmarksCompanion.insert(
          surahId: 1,
          ayahId: 1,
          ayahNumber: 1,
        ),
      );
      expect(first, 1);
      expect(second, 0); // ignored
      final all = await db.select(db.bookmarks).get();
      expect(all, hasLength(1));
    });

    test('deleteByAyah removes the bookmark for that ayah only',
        () async {
      await seedFixture();
      for (final id in [1, 2, 3]) {
        await bookmarkDao.insertBookmark(
          BookmarksCompanion.insert(
            surahId: 1,
            ayahId: id,
            ayahNumber: id,
          ),
        );
      }
      final deleted = await bookmarkDao.deleteByAyah(2);
      expect(deleted, 1);
      final remaining =
          await bookmarkDao.watchBookmarkedAyahIds().first;
      expect(remaining, {1, 3});
    });

    test('watchIsBookmarked emits true / false on toggle', () async {
      await seedFixture();
      // Initially false.
      expect(await bookmarkDao.watchIsBookmarked(5).first, isFalse);
      await bookmarkDao.insertBookmark(
        BookmarksCompanion.insert(surahId: 1, ayahId: 5, ayahNumber: 5),
      );
      expect(await bookmarkDao.watchIsBookmarked(5).first, isTrue);
      await bookmarkDao.deleteByAyah(5);
      expect(await bookmarkDao.watchIsBookmarked(5).first, isFalse);
    });

    test('watchAll orders by createdAt desc (newest first)', () async {
      await seedFixture();
      await bookmarkDao.insertBookmark(
        BookmarksCompanion.insert(surahId: 1, ayahId: 1, ayahNumber: 1),
      );
      // Sleep so the second bookmark has a strictly later
      // createdAt (the column uses DateTime.now()).
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await bookmarkDao.insertBookmark(
        BookmarksCompanion.insert(surahId: 1, ayahId: 2, ayahNumber: 2),
      );
      final all = await bookmarkDao.watchAll().first;
      expect(all.map((b) => b.ayahId), [2, 1]);
    });
  });

  // ──────────────────────── NotesDao ───────────────────────────

  group('NotesDao', () {
    test('addNote returns a positive id and is readable', () async {
      await seedFixture();
      final id = await notesDao.addNote(ayahId: 1, text: 'first note');
      expect(id, greaterThan(0));
      final list = await notesDao.watchForAyah(1).first;
      expect(list, hasLength(1));
      expect(list.first.textValue, 'first note');
    });

    test('an ayah can hold multiple notes', () async {
      await seedFixture();
      await notesDao.addNote(ayahId: 1, text: 'one');
      await notesDao.addNote(ayahId: 1, text: 'two');
      await notesDao.addNote(ayahId: 2, text: 'three');
      final ayah1 = await notesDao.watchForAyah(1).first;
      final ayah2 = await notesDao.watchForAyah(2).first;
      expect(ayah1.map((n) => n.textValue), ['one', 'two']);
      expect(ayah2.map((n) => n.textValue), ['three']);
    });

    test('updateText replaces the text and bumps updatedAt', () async {
      await seedFixture();
      final id = await notesDao.addNote(ayahId: 1, text: 'old');
      final before = await notesDao.watchForAyah(1).first;
      final originalUpdatedAt = before.first.updatedAt;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final rowsChanged =
          await notesDao.updateText(before.first, 'new');
      expect(rowsChanged, 1);
      final after = await notesDao.watchForAyah(1).first;
      expect(after.first.textValue, 'new');
      expect(
        after.first.updatedAt.isAfter(originalUpdatedAt),
        isTrue,
      );
      // id is unchanged.
      expect(after.first.id, id);
    });

    test('deleteById removes one row; deleteByAyah clears the ayah',
        () async {
      await seedFixture();
      await notesDao.addNote(ayahId: 1, text: 'a');
      await notesDao.addNote(ayahId: 1, text: 'b');
      await notesDao.addNote(ayahId: 2, text: 'c');
      // deleteById: remove just the first note.
      final first = await notesDao.watchForAyah(1).first;
      final rowsDeleted = await notesDao.deleteById(first.first.id);
      expect(rowsDeleted, 1);
      expect(
        (await notesDao.watchForAyah(1).first).map((n) => n.textValue),
        ['b'],
      );
      // deleteByAyah: nuke the rest of ayah 1.
      final cleared = await notesDao.deleteByAyah(1);
      expect(cleared, 1);
      expect(await notesDao.watchForAyah(1).first, isEmpty);
      // Ayah 2 is untouched.
      expect(
        (await notesDao.watchForAyah(2).first).map((n) => n.textValue),
        ['c'],
      );
    });

    test('watchCountForAyah matches the underlying row count',
        () async {
      await seedFixture();
      expect(await notesDao.watchCountForAyah(3).first, 0);
      await notesDao.addNote(ayahId: 3, text: 'x');
      await notesDao.addNote(ayahId: 3, text: 'y');
      await notesDao.addNote(ayahId: 3, text: 'z');
      expect(await notesDao.watchCountForAyah(3).first, 3);
    });
  });

  // ──────────────────────── SurahDao ───────────────────────────

  group('SurahDao', () {
    test('getAll / watchAll / getById / count reflect seed data',
        () async {
      await seedFixture();
      // Two surahs from seedFixture.
      expect(await surahDao.count(), 2);
      final all = await surahDao.getAll();
      expect(all.map((s) => s.id), [1, 2]);
      final fatiha = await surahDao.getById(1);
      expect(fatiha, isNotNull);
      expect(fatiha!.nameTransliteration, 'Al-Fatiha');
      expect(fatiha.ayahCount, 7);
      final missing = await surahDao.getById(99);
      expect(missing, isNull);

      // watchAll emits on insert.
      await db.into(db.surahs).insert(
            SurahsCompanion.insert(
              id: const Value(3),
              nameAr: 'العمران',
              nameEn: 'The Family of Imraan',
              nameTransliteration: 'Aal-Imran',
              revelationType: 'Medinan',
              ayahCount: 200,
              orderInMushaf: 3,
            ),
          );
      final watched = await surahDao.watchAll().first;
      expect(watched, hasLength(3));
    });

    test('insertAll is idempotent (insertOrReplace)', () async {
      await seedFixture();
      // Re-insert the same 2 surahs. Surah 1 changes its
      // name_transliteration; Surah 2 is identical.
      await surahDao.insertAll([
        SurahsCompanion.insert(
          id: const Value(1),
          nameAr: 'الفاتحة',
          nameEn: 'The Opening',
          nameTransliteration: 'Al-Fatiha (revised)',
          revelationType: 'Meccan',
          ayahCount: 7,
          orderInMushaf: 1,
        ),
        SurahsCompanion.insert(
          id: const Value(2),
          nameAr: 'البقرة',
          nameEn: 'The Cow',
          nameTransliteration: 'Al-Baqara',
          revelationType: 'Medinan', // changed
          ayahCount: 286,
          orderInMushaf: 2,
        ),
      ]);
      expect(await surahDao.count(), 2);
      final fatiha = await surahDao.getById(1);
      expect(fatiha!.nameTransliteration, 'Al-Fatiha (revised)');
      final baqara = await surahDao.getById(2);
      // The second insert wins on conflicting columns; the
      // unchanged rows are also touched.
      expect(baqara!.revelationType, 'Medinan');
    });
  });
}
