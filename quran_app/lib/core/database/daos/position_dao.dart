import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'position_dao.g.dart';

/// One row per (date, surah) of the reading history. Used by the
/// statistics screen to render daily/weekly totals and a 7-day bar
/// chart. Carries the surah id so callers can render a per-surah
/// breakdown if they want.
class DailyReading {
  const DailyReading({
    required this.date,
    required this.surahId,
    required this.ayahsRead,
  });

  /// ISO-8601 calendar date (`YYYY-MM-DD`) in local time.
  final String date;
  final int surahId;
  final int ayahsRead;
}

@DriftAccessor(tables: [LastPosition, ReadingHistory])
class PositionDao extends DatabaseAccessor<AppDatabase>
    with _$PositionDaoMixin {
  PositionDao(super.db);

  Stream<LastPositionData?> watchLast() => (select(lastPosition)
        ..where((p) => p.id.equals(1)))
      .watchSingleOrNull();

  /// UPSERT the single "last position" row (PK = 1). Called every
  /// time the reader opens an ayah so the home screen's "Continue
  /// reading" card can deep-link back to where the user left off.
  /// The `page` column is left NULL — we don't track mushaf page
  /// numbers in this app yet (the seed doesn't populate them).
  Future<void> setLast({
    required int surahId,
    required int ayahId,
  }) async {
    await into(lastPosition).insertOnConflictUpdate(
      LastPositionCompanion.insert(
        id: const Value(1),
        surahId: surahId,
        ayahId: ayahId,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Атомарный UPSERT по (date, surah_id). Добавляет ayahsRead к существующему
  /// значению или создаёт новую строку. Один SQL-запрос без race-condition.
  Future<void> recordReading({
    required DateTime date,
    required int surahId,
    int ayahsRead = 1,
  }) async {
    final key = _isoDate(date);
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

  /// Aggregate sum of `ayahs_read` for the calendar window that
  /// includes [start] and [end] (both inclusive, local time). The
  /// reader is currently at the end of the list so the Statistics
  /// screen can decide the visual order.
  Stream<int> watchAyahsInRange(DateTime start, DateTime end) {
    return customSelect(
      'SELECT COALESCE(SUM(ayahs_read), 0) AS s FROM reading_history '
      'WHERE date >= ? AND date <= ?',
      variables: [
        Variable.withString(_isoDate(start)),
        Variable.withString(_isoDate(end)),
      ],
      readsFrom: {readingHistory},
    ).watchSingle().map((r) => r.read<int>('s'));
  }

  /// All `(date, surah_id, ayahs_read)` rows in [start]..[end]
  /// inclusive. Used by the 7-day bar chart in Statistics. The
  /// caller is responsible for ordering — Drift's plain `ORDER BY`
  /// would sort the strings, which is exactly the calendar order
  /// we want, so we sort server-side.
  Stream<List<DailyReading>> watchByDateRange(
    DateTime start,
    DateTime end,
  ) {
    return customSelect(
      'SELECT date, surah_id, ayahs_read FROM reading_history '
      'WHERE date >= ? AND date <= ? '
      'ORDER BY date',
      variables: [
        Variable.withString(_isoDate(start)),
        Variable.withString(_isoDate(end)),
      ],
      readsFrom: {readingHistory},
    ).watch().map(
          (rows) => rows
              .map(
                (r) => DailyReading(
                  date: r.read<String>('date'),
                  surahId: r.read<int>('surah_id'),
                  ayahsRead: r.read<int>('ayahs_read'),
                ),
              )
              .toList(),
        );
  }

  /// Total ayahs read across the whole history. Used for the
  /// "all-time" stat on the Statistics screen.
  Stream<int> watchTotalAyahs() {
    return customSelect(
      'SELECT COALESCE(SUM(ayahs_read), 0) AS s FROM reading_history',
      readsFrom: {readingHistory},
    ).watchSingle().map((r) => r.read<int>('s'));
  }

  /// Current consecutive-day reading streak ending at [now]
  /// (default: today). The streak is the count of calendar days,
  /// counting backwards from `now`, on which the user read at
  /// least one ayah. A day with zero reading breaks the streak.
  ///
  /// Implementation walks the `reading_history` rows for the
  /// trailing 366 days (sufficient for any realistic streak) and
  /// counts back from `now`'s date while the sum for that day is
  /// non-zero. We don't watch the underlying stream for every
  /// date separately — one SUM-GROUP-BY query covers it.
  Stream<int> watchStreakDays({DateTime? now}) {
    final today = now ?? DateTime.now();
    final earliest = today.subtract(const Duration(days: 366));
    return watchByDateRange(earliest, today).map((rows) {
      if (rows.isEmpty) return 0;
      // Pivot into a `date -> ayahsRead` map so the streak loop
      // is O(distinct days) rather than O(streak * surahs).
      final byDate = <String, int>{};
      for (final r in rows) {
        byDate.update(r.date, (v) => v + r.ayahsRead,
            ifAbsent: () => r.ayahsRead);
      }
      var streak = 0;
      var cursor = today;
      while (true) {
        final key = _isoDate(cursor);
        final read = byDate[key] ?? 0;
        // Allow a one-day grace period: if the user hasn't read
        // today yet but did read yesterday, the streak is still
        // alive. This avoids resetting the streak to 0 just
        // because the user opens the app in the morning before
        // reading.
        if (read == 0) {
          if (streak == 0 && _isoDate(cursor) == _isoDate(today)) {
            cursor = cursor.subtract(const Duration(days: 1));
            continue;
          }
          break;
        }
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return streak;
    });
  }
}

/// Format a [DateTime] as `YYYY-MM-DD` in local time. The
/// `reading_history` table stores dates as text (so a single
/// column serves the UNIQUE constraint) and we want lexicographic
/// ordering to match chronological ordering — both requirements
/// are satisfied by ISO-8601 calendar dates.
String _isoDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}
