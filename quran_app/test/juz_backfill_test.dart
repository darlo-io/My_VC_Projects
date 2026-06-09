import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/data/juz_mapping.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/database/daos/ayah_dao.dart';

/// In-memory tests for the Juz-based lookups on [AyahDao]:
/// `juzForAyah` (pure function), `watchByJuz` (DB-backed
/// ayahs_fts-free stream), and `backfillJuzColumn` (one-shot
/// migration that populates the `Ayahs.juz` column from
/// [kJuzStarts]).
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

  /// Seed Al-Fatiha (7 ayahs) and An-Naba (1 ayah). Al-Fatiha
  /// spans Juz 1 only; An-Naba ayah 1 is the start of Juz 30.
  /// Spanning multiple Juz's would need a much bigger fixture
  /// and is tested indirectly via `juzForAyah`.
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

  group('AyahDao.juzForAyah', () {
    test('returns 1 for Al-Fatiha 1', () {
      expect(ayahDao.juzForAyah(1, 1), 1);
    });

    test('returns 1 for any ayah in Al-Fatiha', () {
      for (var i = 1; i <= 7; i++) {
        expect(ayahDao.juzForAyah(1, i), 1, reason: 'ayah $i');
      }
    });

    test('returns 2 for Al-Baqara 142', () {
      expect(ayahDao.juzForAyah(2, 142), 2);
    });

    test('returns 30 for An-Naba 1', () {
      expect(ayahDao.juzForAyah(78, 1), 30);
    });

    test('defensively returns 1 for inputs before the first boundary',
        () {
      // Surah 0 doesn't exist; the function should still return
      // something sane (1) rather than throwing.
      expect(ayahDao.juzForAyah(0, 0), 1);
    });
  });

  group('AyahDao.watchByJuz', () {
    test('returns empty for out-of-range juz numbers', () async {
      await seedFixture();
      expect(await ayahDao.watchByJuz(0).first, isEmpty);
      expect(await ayahDao.watchByJuz(31).first, isEmpty);
    });

    test('returns Al-Fatiha 1-7 for Juz 1', () async {
      await seedFixture();
      final ayahs = await ayahDao.watchByJuz(1).first;
      expect(ayahs.map((a) => a.ayahNumber), [1, 2, 3, 4, 5, 6, 7]);
      expect(ayahs.every((a) => a.surahId == 1), isTrue);
    });

    test('returns An-Naba 1 for Juz 30 (the Juz starts at the end of the Quran)',
        () async {
      await seedFixture();
      final ayahs = await ayahDao.watchByJuz(30).first;
      expect(ayahs.map((a) => a.surahId), [78]);
      expect(ayahs.map((a) => a.ayahNumber), [1]);
    });
  });

  group('AyahDao.backfillJuzColumn', () {
    test('populates the juz column on rows where it was null', () async {
      await seedFixture();
      // Sanity: no rows are backfilled before the call.
      final before = await db.select(db.ayahs).get();
      expect(before.every((a) => a.juz == null), isTrue);

      final updated = await ayahDao.backfillJuzColumn();
      expect(updated, before.length);

      // Al-Fatiha 1-7 → Juz 1. An-Naba 1 → Juz 30.
      final after = await db.select(db.ayahs).get();
      for (final a in after) {
        if (a.surahId == 1) {
          expect(a.juz, 1, reason: 'surah 1 ayah ${a.ayahNumber}');
        } else if (a.surahId == 78) {
          expect(a.juz, 30, reason: 'surah 78 ayah ${a.ayahNumber}');
        }
      }
    });

    test('is idempotent: a second call updates zero rows', () async {
      await seedFixture();
      await ayahDao.backfillJuzColumn();
      final updated = await ayahDao.backfillJuzColumn();
      expect(updated, 0);
    });
  });
}
