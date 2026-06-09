import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/database/daos/position_dao.dart';

/// In-memory tests for the [PositionDao.watchLastWithSurah] JOIN
/// stream. Before the previous fix, the home screen built the same
/// projection by hand from three separate lookups.
///
/// Runs under `flutter test`. Note: on Windows hosts, `flutter test`
/// itself crashes inside flutter_tester (a known WebSocket issue).
/// Run the suite on Linux or macOS, or in CI.
void main() {
  late AppDatabase db;
  late PositionDao dao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.positionDao;
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
  }

  group('PositionDao.watchLastWithSurah', () {
    test('emits LastReadPosition.empty when no position is recorded',
        () async {
      final last = await dao.watchLastWithSurah().first;
      expect(last.surahId, 0);
      expect(last.ayahNumber, 0);
      expect(last.surahName, '');
      expect(last.progress, 0.0);
    });

    test('projects the surah name and ayah number for a recorded '
        'position', () async {
      await seedAlFatiha();
      await dao.setLast(surahId: 1, ayahId: 3);
      final last = await dao.watchLastWithSurah().first;
      expect(last.surahId, 1);
      expect(last.ayahNumber, 3);
      expect(last.surahName, 'Al-Fatiha');
    });

    test('progress is ayahNumber / surah.ayahCount, clamped to [0, 1]',
        () async {
      await seedAlFatiha();
      // 3 / 7 ~= 0.4286
      await dao.setLast(surahId: 1, ayahId: 3);
      final last = await dao.watchLastWithSurah().first;
      expect(last.progress, closeTo(3 / 7, 1e-9));
    });

    test('falls back gracefully when the recorded ayahId no longer '
        'exists in the ayahs table', () async {
      // The reader_screen resolves the actual ayah row before
      // calling setLast, so a stale ayahId is unlikely — but if
      // the user wipes their DB and re-seeds between sessions,
      // the LEFT JOIN gives us a null `a.ayah_number` and we
      // fall back to `lp.ayah_id` (the route-stored value).
      await seedAlFatiha();
      await dao.setLast(surahId: 1, ayahId: 99);
      final last = await dao.watchLastWithSurah().first;
      expect(last.surahId, 1);
      // ayahs row is missing, but surah name and fallback
      // ayahNumber still resolve.
      expect(last.surahName, 'Al-Fatiha');
      expect(last.ayahNumber, 99);
    });
  });
}
