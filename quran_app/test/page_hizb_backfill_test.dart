import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/database/daos/ayah_dao.dart';

/// Tests for [AyahDao.backfillPageAndHizbColumn]. Verifies that
/// the in-memory [kQuranLayout] gets pushed into the `Ayahs.page`
/// and `Ayahs.hizb` columns and that re-runs are idempotent.
///
/// Runs under `flutter test`. Note: on Windows hosts, `flutter test`
/// itself crashes inside flutter_tester (a known WebSocket issue).
/// Run the suite on Linux or macOS, or in CI.
void main() {
  late AppDatabase db;
  late AyahDao ayahDao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ayahDao = db.ayahDao;
  });

  tearDown(() async {
    await db.close();
  });

  /// Seed Al-Fatiha (7 ayahs) and An-Naba (1 ayah).
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
    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
            id: const Value(78),
            nameAr: 'النبأ',
            nameEn: 'The Tidings',
            nameTransliteration: 'An-Naba',
            revelationType: 'Meccan',
            ayahCount: 1,
            orderInMushaf: 78,
          ),
        );
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
    await db.into(db.ayahs).insert(
          AyahsCompanion.insert(
            id: const Value(100),
            surahId: 78,
            ayahNumber: 1,
            textUthmani: 'an-naba 1',
            textNormalized: 'an-naba 1',
          ),
        );
  }

  group('AyahDao.backfillPageAndHizbColumn', () {
    test('returns 0 on an empty table without touching the DB', () async {
      final updated = await ayahDao.backfillPageAndHizbColumn();
      expect(updated, 0);
    });

    test('populates page and hizb on rows that had them null', () async {
      await seedFixture();
      // Sanity: all rows start with page/hizb null.
      final before = await db.select(db.ayahs).get();
      expect(before.every((a) => a.page == null), isTrue);
      expect(before.every((a) => a.hizb == null), isTrue);

      final updated = await ayahDao.backfillPageAndHizbColumn();
      // Only the 8 fixture rows are in the DB; everything else
      // is skipped because there's no matching row to UPDATE.
      expect(updated, 8);

      final after = await db.select(db.ayahs).get();
      // Al-Fatiha 1 is the very first row in the mushaf, so it
      // gets the very first page/hizb values from kQuranLayout.
      final alFatiha1 = after.firstWhere((a) => a.surahId == 1 && a.ayahNumber == 1);
      expect(alFatiha1.page, isNotNull);
      expect(alFatiha1.hizb, isNotNull);
      // Every row that exists in the fixture has its page and
      // hizb populated.
      expect(after.every((a) => a.page != null), isTrue);
      expect(after.every((a) => a.hizb != null), isTrue);
    });

    test('is idempotent: a second call updates zero rows', () async {
      await seedFixture();
      final first = await ayahDao.backfillPageAndHizbColumn();
      expect(first, 8);
      final second = await ayahDao.backfillPageAndHizbColumn();
      expect(second, 0);
    });

    test('does not touch the juz column (that is a separate backfill)',
        () async {
      await seedFixture();
      await ayahDao.backfillJuzColumn();
      await ayahDao.backfillPageAndHizbColumn();
      final after = await db.select(db.ayahs).get();
      // Juz values are exact (1 for Al-Fatiha, 30 for An-Naba).
      for (final a in after) {
        if (a.surahId == 1) {
          expect(a.juz, 1);
        } else if (a.surahId == 78) {
          expect(a.juz, 30);
        }
        expect(a.page, isNotNull);
        expect(a.hizb, isNotNull);
      }
    });
  });
}
