import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'position_dao.g.dart';

@DriftAccessor(tables: [LastPosition, ReadingHistory])
class PositionDao extends DatabaseAccessor<AppDatabase>
    with _$PositionDaoMixin {
  PositionDao(super.db);

  Stream<LastPositionData?> watchLast() => (select(lastPosition)
        ..where((p) => p.id.equals(1)))
      .watchSingleOrNull();

  /// Атомарный UPSERT по (date, surah_id). Добавляет ayahsRead к существующему
  /// значению или создаёт новую строку. Один SQL-запрос без race-condition.
  Future<void> recordReading({
    required DateTime date,
    required int surahId,
    int ayahsRead = 1,
  }) async {
    final key =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    await customStatement(
      '''
      INSERT INTO reading_history (date, surah_id, ayahs_read)
      VALUES (?, ?, ?)
      ON CONFLICT(date, surah_id) DO UPDATE
        SET ayahs_read = ayahs_read + excluded.ayahs_read
      ''',
      [key, surahId, ayahsRead],
    );
  }
}
