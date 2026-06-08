import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/database/daos/words_dao.dart';

/// In-memory tests for the word-dictionary search methods on
/// [WordsDao]: FTS5-backed prefix search via `words_fts`, and the
/// LIKE-based root lookup used by the "Other words with the same
/// root" section in the learning card.
///
/// Runs under `flutter test` (path_provider is loaded as a plugin
/// but never invoked because we use
/// `AppDatabase.forTesting(NativeDatabase.memory())`).
///
/// Note: on Windows hosts, `flutter test` itself crashes inside
/// flutter_tester (a known WebSocket issue). Run the suite on Linux
/// or macOS, or via `flutter test --platform=vm` after pinning the
/// test runner.
void main() {
  late AppDatabase db;
  late WordsDao wordsDao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    wordsDao = db.wordsDao;
  });

  tearDown(() async {
    await db.close();
  });

  /// Inserts Al-Fatiha (surah 1) with the first ayah split into
  /// 4 words. Two of them share the root رحم (رحمن + رحيم), and
  /// the third and fourth have unrelated roots. This lets us verify
  /// both the FTS5 prefix search and the LIKE-based root search.
  Future<void> seedFixture() async {
    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
            id: const Value(1),
            nameAr: 'الفاتحة',
            nameEn: 'The Opening',
            nameTransliteration: 'Al-Fatiha',
            revelationType: 'Meccan',
            ayahCount: 7,
            orderInMushaf: 1,
          ),
        );
    await db.into(db.ayahs).insert(
          AyahsCompanion.insert(
            id: const Value(1),
            surahId: 1,
            ayahNumber: 1,
            textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
            textNormalized: 'بسم الله الرحمن الرحيم',
          ),
        );
    await db.into(db.words).insert(
          WordsCompanion.insert(
            id: Value(1),
            ayahId: 1,
            position: 1,
            arabic: 'ٱلرَّحْمَٰنِ',
            normalized: 'alrhamn',
            translation: const Value('The Merciful'),
            lemma: const Value('رحمن'),
            root: const Value('رحم'),
          ),
        );
    await db.into(db.words).insert(
          WordsCompanion.insert(
            id: Value(2),
            ayahId: 1,
            position: 2,
            arabic: 'ٱلرَّحِيمِ',
            normalized: 'alrheim',
            translation: const Value('The Compassionate'),
            lemma: const Value('رحيم'),
            root: const Value('رحم'),
          ),
        );
    await db.into(db.words).insert(
          WordsCompanion.insert(
            id: Value(3),
            ayahId: 1,
            position: 3,
            arabic: 'ٱللَّهِ',
            normalized: 'allah',
            translation: const Value('Allah'),
            lemma: const Value('الله'),
            root: const Value('اله'),
          ),
        );
    await db.into(db.words).insert(
          WordsCompanion.insert(
            id: Value(4),
            ayahId: 1,
            position: 4,
            arabic: 'بِسْمِ',
            normalized: 'bism',
            translation: const Value('In the name'),
            lemma: const Value('اسم'),
            root: const Value('سمو'),
          ),
        );
  }

  group('WordsDao.search', () {
    test('returns empty list for empty / banned-only query', () async {
      await seedFixture();
      expect(await wordsDao.search(''), isEmpty);
      expect(await wordsDao.search('"()*:^-+.,;'), isEmpty);
    });

    test('prefix search: typing the first letters of a normalized '
        'form finds the word', () async {
      await seedFixture();
      // 'alrh' is a prefix of 'alrhamn' and 'alrheim'. With the
      // trailing * normalization, the FTS5 query becomes
      // 'alrh*' which matches both رحم-derived words.
      final hits = await wordsDao.search('alrh');
      expect(hits.map((h) => h.wordId).toSet(), {1, 2});
    });

    test('matches by translation column (cross-language search)',
        () async {
      await seedFixture();
      // 'Merciful' is the English translation of word 1.
      final hits = await wordsDao.search('Merciful');
      expect(hits.map((h) => h.wordId), [1]);
    });

    test('matches by lemma (the bucketed morphological form)',
        () async {
      await seedFixture();
      // 'رحمن' is the lemma of word 1.
      final hits = await wordsDao.search('رحمن');
      expect(hits.map((h) => h.wordId), contains(1));
    });

    test('hit carries surah/ayah coordinates for the deep link',
        () async {
      await seedFixture();
      final hits = await wordsDao.search('Merciful');
      expect(hits, hasLength(1));
      expect(hits.first.surahId, 1);
      expect(hits.first.ayahNumber, 1);
      expect(hits.first.arabic, 'ٱلرَّحْمَٰنِ');
    });
  });

  group('WordsDao.searchByRoot', () {
    test('returns empty for empty root', () async {
      await seedFixture();
      expect(await wordsDao.searchByRoot(''), isEmpty);
    });

    test('returns all words sharing a root', () async {
      await seedFixture();
      // Both word 1 and word 2 have root رحم.
      final hits = await wordsDao.searchByRoot('رحم');
      expect(hits.map((h) => h.wordId).toSet(), {1, 2});
    });

    test('excludeWordId drops the seed word from the result list',
        () async {
      await seedFixture();
      final hits = await wordsDao.searchByRoot(
        'رحم',
        excludeWordId: 1,
      );
      expect(hits.map((h) => h.wordId), [2]);
    });

    test('returns no hits for an unknown root', () async {
      await seedFixture();
      expect(await wordsDao.searchByRoot('قرآن'), isEmpty);
    });
  });
}
