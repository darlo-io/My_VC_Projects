import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/database/daos/position_dao.dart';

/// In-memory tests for the last-position round-trip on
/// [PositionDao.setLast] / [PositionDao.watchLast]. Before the
/// previous fix, `setLast` did not exist and the home screen's
/// "Continue reading" card always fell back to Al-Fatiha 1.
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

  group('PositionDao.setLast / watchLast', () {
    test('watchLast emits null when no position has been recorded',
        () async {
      // The reader_screen calls setLast on every mount, so in
      // practice this null-state only appears on first launch.
      final last = await dao.watchLast().first;
      expect(last, isNull);
    });

    test('setLast creates a new last_position row', () async {
      await seedAlFatiha();
      await dao.setLast(surahId: 1, ayahId: 3);
      final last = await dao.watchLast().first;
      expect(last, isNotNull);
      expect(last!.surahId, 1);
      expect(last.ayahId, 3);
    });

    test('setLast is idempotent: second call overwrites the first',
        () async {
      await seedAlFatiha();
      await dao.setLast(surahId: 1, ayahId: 1);
      await dao.setLast(surahId: 1, ayahId: 5);
      final last = await dao.watchLast().first;
      expect(last!.surahId, 1);
      expect(last.ayahId, 5);
      // No duplicate rows — the single-row UPSERT keeps the table
      // at exactly one record.
      final count = await db.managers.lastPosition.count();
      expect(count, 1);
    });

    test('setLast updates the updatedAt timestamp', () async {
      await seedAlFatiha();
      await dao.setLast(surahId: 1, ayahId: 1);
      final first = await dao.watchLast().first;
      // 5ms gap so the timestamp is observably different.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await dao.setLast(surahId: 1, ayahId: 4);
      final second = await dao.watchLast().first;
      expect(second!.updatedAt.isAfter(first!.updatedAt), isTrue);
    });
  });
}
