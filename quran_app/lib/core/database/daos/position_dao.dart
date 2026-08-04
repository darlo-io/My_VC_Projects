import 'package:drift/drift.dart';

import '../app_database.dart';
import '../models/last_read_position.dart';
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

@DriftAccessor(tables: [LastPosition, ReadingHistory, Surahs, Ayahs])
class PositionDao extends DatabaseAccessor<AppDatabase>
    with _$PositionDaoMixin {
  PositionDao(super.db);

  Stream<LastPositionData?> watchLast() => (select(lastPosition)
        ..where((p) => p.id.equals(1)))
      .watchSingleOrNull();

  /// Stream of the last reading position enriched with the
  /// surrounding surah metadata and a `[0.0, 1.0]` progress ratio
  /// (computed as `ayahNumber / surah.ayahCount`).
  ///
  /// Single JOIN query rather than three separate lookups (last
  /// position → surah → ayah) — the home screen can render
  /// "Continue reading" without a fan-out on every state change.
  /// Emits [LastReadPosition.empty] when the position row is
  /// missing (i.e. the user hasn't opened a surah yet).
  Stream<LastReadPosition> watchLastWithSurah() {
    return customSelect(
      '''
      SELECT
        lp.surah_id    AS lp_surah_id,
        lp.ayah_id     AS lp_ayah_id,
        lp.updated_at  AS lp_updated_at,
        s.ayah_count   AS s_ayah_count,
        s.name_transliteration AS s_name_transliteration,
        a.ayah_number  AS a_ayah_number
      FROM last_position lp
      LEFT JOIN surahs s ON s.id = lp.surah_id
      LEFT JOIN ayahs  a ON a.id = lp.ayah_id
      WHERE lp.id = 1
      ''',
      readsFrom: {lastPosition, surahs, ayahs},
    ).watchSingleOrNull().map(
      (row) {
        if (row == null) {
          return const LastReadPosition.empty();
        }
        final lpSurahId = row.readNullable<int>('lp_surah_id');
        if (lpSurahId == null) {
          return const LastReadPosition.empty();
        }
        final ayahCount = row.readNullable<int>('s_ayah_count') ?? 0;
        // Prefer the live ayah row's ordinal; fall back to the
        // route-stored `lp.ayah_id` only if the row was deleted
        // out from under us (shouldn't happen but the type is
        // nullable).
        final liveAyahNumber = row.readNullable<int>('a_ayah_number');
        final inSurahAyah =
            liveAyahNumber ?? row.read<int>('lp_ayah_id');
        final progress = ayahCount > 0
            ? (inSurahAyah / ayahCount).clamp(0.0, 1.0)
            : 0.0;
        return LastReadPosition(
          surahId: lpSurahId,
          surahName:
              row.readNullable<String>('s_name_transliteration') ?? '',
          ayahNumber: inSurahAyah,
          progress: progress,
          // `ayahCount` нужен для проверки `isCompleted` на главной.
          // `progress` — это double и при `N / N` может быть
          // `0.99999...` из-за floating-point неточностей, а не ровно
          // `1.0`. Сравнение по int (`ayahNumber >= ayahCount`) —
          // надёжный способ определить «сура прочитана до конца».
          ayahCount: ayahCount,
        );
      },
    );
  }

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

  /// Round 9.6 (code review #C5): `Map<date, totalAyahs>` для окна
  /// `[start..end]`. Использует SQL `SUM(...) GROUP BY date` —
  /// один round-trip возвращает готовый pivot для подсчёта
  /// streak'а (раньше `watchStreakDays` делал group-by в Dart,
  /// что для 366-дневного окна = 41k строк in-memory).
  Stream<Map<String, int>> watchDailyTotals(
    DateTime start,
    DateTime end,
  ) {
    return customSelect(
      'SELECT date, COALESCE(SUM(ayahs_read), 0) AS total '
      'FROM reading_history '
      'WHERE date >= ? AND date <= ? '
      'GROUP BY date',
      variables: [
        Variable.withString(_isoDate(start)),
        Variable.withString(_isoDate(end)),
      ],
      readsFrom: {readingHistory},
    ).watch().map(
          (rows) => <String, int>{
            for (final r in rows)
              r.read<String>('date'): r.read<int>('total'),
          },
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
  /// Round 9.6 (code review #C5): теперь использует
  /// [watchDailyTotals] — один round-trip с `SUM(...) GROUP BY
  /// date` в SQL, вместо raw rows + in-memory pivot. Для
  /// 366-дневного окна это убирает передачу ~41k строк.
  Stream<int> watchStreakDays({DateTime? now}) {
    final today = now ?? DateTime.now();
    final earliest = today.subtract(const Duration(days: 366));
    return watchDailyTotals(earliest, today).map((byDate) {
      if (byDate.isEmpty) return 0;
      var streak = 0;
      var graceDays = 0;
      var cursor = today;
      while (true) {
        final key = _isoDate(cursor);
        final read = byDate[key] ?? 0;
        // Round 9.6 (code review #C4): разрешаем до 1 grace-day в
        // середине стрика. Раньше grace применялся только к
        // сегодняшнему дню (когда пользователь открывает
        // приложение утром и ещё не читал). Теперь если
        // пользователь не читал вчера И сегодня, но читал
        // позавчера — стрик **сохраняется** (есть 1 grace-day).
        // Это убирает раздражение у пользователей, которые
        // читают через день.
        if (read == 0) {
          if (graceDays < 1) {
            graceDays++;
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

  /// Сколько сур прочитано хотя бы на 1 аят. Используется для
  /// `statsSurahsRead` (X из 114) и для "Progress по джузам" (X джузов
  /// завершено полностью).
  ///
  /// `minRatio = 1.0` означает "вся сура прочитана". Меньшие значения
  /// полезны для "X% суры прочитано".
  Stream<int> watchSurahsReadCount({double minRatio = 0.0}) {
    return customSelect(
      '''
      SELECT COUNT(*) AS c
      FROM (
        SELECT
          a.surah_id,
          CAST(SUM(CASE WHEN rh.ayahs_read > 0 THEN 1 ELSE 0 END) AS REAL)
            / (SELECT COUNT(*) FROM ayahs a2 WHERE a2.surah_id = a.surah_id) AS ratio
        FROM reading_history rh
        JOIN ayahs a ON a.id = rh.ayah_id
        GROUP BY a.surah_id
      )
      WHERE ratio >= ?
      ''',
      variables: [Variable.withReal(minRatio)],
      readsFrom: {readingHistory, ayahs},
    ).watchSingle().map((r) => r.read<int>('c'));
  }

  /// Progress по каждому из 30 джузов: `(juzNumber, read, total)`.
  /// `read` — кол-во уникальных аятов этого джуза, на которые есть
  /// запись в `reading_history`; `total` — общее кол-во аятов джуза.
  ///
  /// `progress = read / total` ∈ [0, 1].
  Stream<List<JuzProgress>> watchJuzProgress() {
    return customSelect(
      '''
      SELECT
        a.juz        AS juz,
        COUNT(DISTINCT a.id) AS read_count,
        (SELECT COUNT(*) FROM ayahs a2 WHERE a2.juz = a.juz) AS total
      FROM ayahs a
      WHERE a.juz IS NOT NULL
        AND a.id IN (
          SELECT DISTINCT ayah_id FROM reading_history WHERE ayahs_read > 0
        )
      GROUP BY a.juz
      ''',
      readsFrom: {ayahs, readingHistory},
    ).watch().map((rows) {
      final byJuz = <int, JuzProgress>{};
      for (final r in rows) {
        final juz = r.read<int>('juz');
        final read = r.read<int>('read_count');
        final total = r.read<int>('total');
        byJuz[juz] = JuzProgress(
          juz: juz,
          read: read,
          total: total,
          ratio: total == 0 ? 0.0 : (read / total).clamp(0.0, 1.0),
        );
      }
      return byJuz;
    }).map((byJuz) {
      // Дополняем пустыми записями для джузов, по которым ещё нет
      // чтения (на свежем install — все 30 джузов с ratio 0).
      return List<JuzProgress>.generate(30, (i) {
        final n = i + 1;
        return byJuz[n] ?? JuzProgress(juz: n, read: 0, total: 0, ratio: 0.0);
      });
    });
  }

  /// Текущий «рекорд по дням» — максимальное кол-во аятов,
  /// прочитанных за один день за всё время. Используется для
  /// achievement «New record».
  Stream<int> watchMaxAyahsInADay() {
    return customSelect(
      'SELECT COALESCE(MAX(daily_sum), 0) AS m FROM '
      '(SELECT date, SUM(ayahs_read) AS daily_sum '
      'FROM reading_history GROUP BY date)',
      readsFrom: {readingHistory},
    ).watchSingle().map((r) => r.read<int>('m'));
  }

  /// Общее время чтения (в секундах). На MVP v0.1
  /// `reading_history` хранит только `ayahs_read`, без
  /// `duration_seconds` — поэтому время чтения **оценивается**
  /// Round 9.6 (code review #M3): магическое число `* 3` вынесено
  /// в `_kSecondsPerAyahEstimate = 3` named constant. Это не меняет
  /// поведение, но даёт единую точку настройки если маркетинг
  /// захочет «среднее время чтения» = 2.5s/ayah или 4s/ayah.
  /// В будущем — заменить на реальный замер (см. ARCHITECTURE
  /// §19: "длительность чтения").
  static const _kSecondsPerAyahEstimate = 3;

  /// Общее время чтения (в секундах). На MVP v0.1
  /// `reading_history` хранит только `ayahs_read`, без
  /// `duration_seconds` — поэтому время чтения **оценивается**
  /// как `ayahs_read * [_kSecondsPerAyahEstimate]` (среднее
  /// время чтения одного аята, ~20 слов по 0.15с/слово).
  Stream<int> watchReadingTimeSeconds() {
    return customSelect(
      'SELECT COALESCE(SUM(ayahs_read), 0) * ? AS s FROM reading_history',
      variables: [Variable.withInt(_kSecondsPerAyahEstimate)],
      readsFrom: {readingHistory},
    ).watchSingle().map((r) => r.read<int>('s'));
  }
}

/// Прогресс по одному джузу.
class JuzProgress {
  const JuzProgress({
    required this.juz,
    required this.read,
    required this.total,
    required this.ratio,
  });
  final int juz; // 1..30
  final int read;
  final int total;
  final double ratio; // [0.0, 1.0]
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
