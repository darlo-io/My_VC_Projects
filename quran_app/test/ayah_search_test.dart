import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/database/daos/ayah_dao.dart';
import 'package:quran_app/core/database/daos/translation_dao.dart';

/// In-memory tests for the FTS5-backed search methods on [AyahDao]
/// and [TranslationDao].
///
/// Uses an in-memory [NativeDatabase] so the suite is hermetic and
/// fast. Runs under `flutter test` (path_provider is loaded as a
/// plugin but never invoked because we use
/// `AppDatabase.forTesting(NativeDatabase.memory())`).
///
/// Note: on Windows hosts, `flutter test` itself crashes inside
/// flutter_tester (a known WebSocket issue). Run the suite on Linux
/// or macOS, or via `flutter test --platform=vm` after pinning the
/// test runner.
void main() {
  late AppDatabase db;
  late AyahDao ayahDao;
  late TranslationDao translationDao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ayahDao = db.ayahDao;
    translationDao = db.translationDao;
  });

  tearDown(() async {
    await db.close();
  });

  /// Inserts a small fixture: Al-Fatiha (surah 1, 7 ayahs) with
  /// recognisable Arabic, plus a single Kuliev Russian translation
  /// for ayah 1, and a single Sahih English translation for ayah 5.
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
    final ayahFixtures = <List<Object>>[
      [1, 1, 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', 'بسم الله الرحمن الرحيم'],
      [2, 1, 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ', 'الحمد لله رب العالمين'],
      [3, 1, 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', 'الرحمن الرحيم'],
      [4, 1, 'مَٰلِكِ يَوْمِ ٱلدِّينِ', 'مالك يوم الدين'],
      [5, 1, 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', 'إياك نعبد وإياك نستعين'],
      [6, 1, 'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ', 'اهدنا الصراط المستقيم'],
      [7, 1, 'صِرَٰطَ ٱلَّذِينَ أَنْعَمْتَ عَلَيْهِمْ', 'صراط الذين انعمت عليهم'],
    ];
    for (final row in ayahFixtures) {
      await db.into(db.ayahs).insert(
            AyahsCompanion.insert(
              id: Value(row[0] as int),
              surahId: 1,
              ayahNumber: row[1] as int,
              textUthmani: row[2] as String,
              textNormalized: row[3] as String,
            ),
          );
    }
    // Translator 1: Russian Kuliev. Translator 2: English Sahih.
    await db.into(db.translators).insert(
          TranslatorsCompanion.insert(
            id: const Value(1),
            name: 'Kuliev',
            languageCode: 'ru',
            source: 'https://quran.com',
          ),
        );
    await db.into(db.translators).insert(
          TranslatorsCompanion.insert(
            id: const Value(2),
            name: 'Sahih International',
            languageCode: 'en',
            source: 'https://quran.com',
          ),
        );
    await db.into(db.translations).insert(
          TranslationsCompanion.insert(
            ayahId: 1,
            translatorId: 1,
            languageCode: 'ru',
            textValue: 'Милость Аллаха и Его милосердие',
          ),
        );
    await db.into(db.translations).insert(
          TranslationsCompanion.insert(
            ayahId: 5,
            translatorId: 2,
            languageCode: 'en',
            textValue: 'It is You we worship and You we ask for help',
          ),
        );
  }

  group('AyahDao.searchByText', () {
    test('returns empty list for empty/whitespace query', () async {
      await seedFixture();
      expect(await ayahDao.searchByText(''), isEmpty);
      expect(await ayahDao.searchByText('   '), isEmpty);
    });

    test('strips FTS5 reserved characters safely', () async {
      await seedFixture();
      // All banned characters. Should not throw; should return no
      // hits because no Arabic token remains.
      expect(await ayahDao.searchByText('"()*:^-+.,;'), isEmpty);
    });

    test('finds ayahs by prefix match on the Arabic normalized form',
        () async {
      await seedFixture();
      // "الرحمن" appears in ayahs 1 and 3.
      final hits = await ayahDao.searchByText('الرحمن');
      expect(hits.map((h) => h.ayahId).toSet(), {1, 3});
    });

    test('prefix search: typing the first letters of الرحمن finds it',
        () async {
      await seedFixture();
      // "الرح" is a prefix of "الرحمن". Without the trailing *
      // normalization, the search would miss it.
      final hits = await ayahDao.searchByText('الرح');
      expect(hits.map((h) => h.ayahId).toSet(), {1, 3});
    });

    test('multi-word query requires both tokens (FTS5 implicit AND)',
        () async {
      await seedFixture();
      // "الرحمن إياك" — only ayah 1 has both (or rather, only ayah 1
      // and 3 have الرحمن, but only ayah 5 has إياك). The intersection
      // is empty.
      final hits = await ayahDao.searchByText('الرحمن إياك');
      expect(hits, isEmpty);
    });

    test('returns up to [limit] hits and orders by surah/ayah',
        () async {
      await seedFixture();
      final hits = await ayahDao.searchByText('الرحمن', limit: 1);
      expect(hits, hasLength(1));
      expect(hits.first.surahId, 1);
      expect(hits.first.ayahNumber, 1);
    });

    test('hit carries surah name for the result row UI', () async {
      await seedFixture();
      final hits = await ayahDao.searchByText('الرحمن');
      expect(hits, isNotEmpty);
      expect(hits.first.surahNameAr, 'الفاتحة');
      expect(hits.first.textUthmani, isNotEmpty);
    });
  });

  group('TranslationDao.search', () {
    test('returns empty list for empty query', () async {
      await seedFixture();
      expect(
        await translationDao.search(query: '', languageCode: 'en'),
        isEmpty,
      );
    });

    test('matches English translation in the right language only',
        () async {
      await seedFixture();
      // "worship" exists only in the English translation of ayah 5.
      final enHits = await translationDao.search(
        query: 'worship',
        languageCode: 'en',
      );
      expect(enHits.map((h) => h.ayahId), [5]);
      expect(enHits.first.translatorName, 'Sahih International');
      // Russian query for the same word yields no hits.
      final ruHits = await translationDao.search(
        query: 'worship',
        languageCode: 'ru',
      );
      expect(ruHits, isEmpty);
    });

    test('matches Russian translation and exposes translator name',
        () async {
      await seedFixture();
      // "милость" appears in the Kuliev translation of ayah 1.
      final hits = await translationDao.search(
        query: 'милость',
        languageCode: 'ru',
      );
      expect(hits.map((h) => h.ayahId), [1]);
      expect(hits.first.translatorName, 'Kuliev');
    });
  });
}
