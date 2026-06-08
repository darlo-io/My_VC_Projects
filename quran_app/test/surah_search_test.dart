import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/database/daos/surah_dao.dart';
import 'package:quran_app/core/search/fts_query.dart';

/// Tests for [SurahDao.searchByText] (substring match on the three
/// name columns) and the shared [buildFtsPrefixQuery] helper
/// (FTS5 reserved-character sanitization).
///
/// Runs under `flutter test`. Note: on Windows hosts, `flutter test`
/// itself crashes inside flutter_tester (a known WebSocket issue).
/// Run the suite on Linux or macOS, or in CI.
void main() {
  late AppDatabase db;
  late SurahDao surahDao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    surahDao = db.surahDao;
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedAlFatiha() async {
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
  }

  group('SurahDao.searchByText', () {
    test('empty query returns no hits', () async {
      await seedAlFatiha();
      expect(await surahDao.searchByText(''), isEmpty);
      expect(await surahDao.searchByText('   '), isEmpty);
    });

    test('matches by transliteration (case-insensitive substring)',
        () async {
      await seedAlFatiha();
      // 'fatih' is a substring of 'Al-Fatiha' (case-insensitive).
      final hits = await surahDao.searchByText('fatih');
      expect(hits.map((h) => h.surahId), [1]);
    });

    test('matches by Arabic name (substring)', () async {
      await seedAlFatiha();
      final hits = await surahDao.searchByText('فتح');
      expect(hits.map((h) => h.surahId), [1]);
    });

    test('strips FTS5 reserved characters safely', () async {
      await seedAlFatiha();
      // No FTS5 reserved character should ever reach the LIKE
      // pattern. The search should treat this as "no hits" rather
      // than throwing or returning a wildcard sweep.
      expect(
        await surahDao.searchByText('"()*:^-+.,;'),
        isEmpty,
      );
    });

    test('numeric query matches by surah id', () async {
      await seedAlFatiha();
      // Typing "1" should match the surah with id == 1.
      final hits = await surahDao.searchByText('1');
      expect(hits.map((h) => h.surahId), [1]);
    });
  });

  group('buildFtsPrefixQuery', () {
    test('empty input returns empty string', () {
      expect(buildFtsPrefixQuery(''), '');
      expect(buildFtsPrefixQuery('   '), '');
    });

    test('single token becomes prefix', () {
      expect(buildFtsPrefixQuery('alrhm'), 'alrhm*');
    });

    test('multi-token input AND-joins each token as a prefix', () {
      expect(
        buildFtsPrefixQuery('alrhm alrheim'),
        'alrhm* alrheim*',
      );
    });

    test('strips FTS5 reserved characters from each token', () {
      // '*' and '"' must be removed before reaching the MATCH.
      expect(buildFtsPrefixQuery('a"l*r-h+m'), 'alrhm*');
    });

    test('drops tokens that are entirely banned characters', () {
      // All characters in the first token are banned, so the
      // resulting query contains only the second token.
      expect(buildFtsPrefixQuery('"*"  alrhm'), 'alrhm*');
    });
  });
}
