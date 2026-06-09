import 'package:drift/drift.dart';

import '../../data/juz_mapping.dart';
import '../../search/fts_query.dart';
import '../app_database.dart';
import '../tables.dart';

part 'ayah_dao.g.dart';

/// Lightweight projection used by [AyahDao.searchByText]. Carries the
/// minimum data the search-result UI needs to render a row and deep-link
/// into the reader (without a second round-trip to load the full Ayah).
class AyahSearchHit {
  const AyahSearchHit({
    required this.ayahId,
    required this.surahId,
    required this.ayahNumber,
    required this.surahNameAr,
    required this.textUthmani,
    required this.textNormalized,
  });

  final int ayahId;
  final int surahId;
  final int ayahNumber;
  final String surahNameAr;
  final String textUthmani;
  final String textNormalized;
}

@DriftAccessor(tables: [Ayahs, Words])
class AyahDao extends DatabaseAccessor<AppDatabase> with _$AyahDaoMixin {
  AyahDao(super.db);

  Stream<List<Ayah>> watchBySurah(int surahId) =>
      (select(ayahs)
            ..where((a) => a.surahId.equals(surahId))
            ..orderBy([(a) => OrderingTerm.asc(a.ayahNumber)]))
          .watch();

  Future<Ayah?> getById(int id) =>
      (select(ayahs)..where((a) => a.id.equals(id))).getSingleOrNull();

  /// Look up the unique ayah row that lives in [surahId] and has
  /// [ayahNumber] (1-based ordinal within the surah). Returns
  /// `null` if the combination doesn't exist (e.g. ayah number out
  /// of range, or surahId doesn't exist in the seed).
  Future<Ayah?> getBySurahAndNumber(int surahId, int ayahNumber) =>
      (select(ayahs)
            ..where(
              (a) => a.surahId.equals(surahId) &
                  a.ayahNumber.equals(ayahNumber),
            ))
          .getSingleOrNull();

  /// Returns the 1-based Juz number that contains the ayah at
  /// [surahId]:[ayahNumber]. Pure function of the [kJuzStarts]
  /// table — no DB roundtrip. Returns 1 (Al-Fatiha) as a defensive
  /// default for inputs that fall before the first boundary.
  int juzForAyah(int surahId, int ayahNumber) {
    for (var i = kJuzStarts.length - 1; i >= 0; i--) {
      final start = kJuzStarts[i];
      if (surahId > start.surahId ||
          (surahId == start.surahId && ayahNumber >= start.ayahNumber)) {
        return i + 1;
      }
    }
    return 1;
  }

  /// Stream of all ayahs in [juz] (1-based, must be in
  /// `1..30`), ordered by their canonical mushaf order. Uses the
  /// [kJuzStarts] table to compute the surah+ayah range and the
  /// end-of-juz boundary, so the query does not depend on
  /// `Ayahs.juz` being populated. Returns an empty stream for
  /// out-of-range `juz` values.
  Stream<List<Ayah>> watchByJuz(int juz, {int? limit}) {
    if (juz < 1 || juz > kJuzStarts.length) {
      return Stream.value(const <Ayah>[]);
    }
    final start = kJuzStarts[juz - 1];
    // Compute the end boundary. For Juz 30, end is the last ayah
    // of the Quran (Surah 114, ayah 6). For all other Juz's we
    // take the start of the next Juz and subtract one ayah.
    final JuzStart end;
    if (juz == kJuzStarts.length) {
      end = const JuzStart(surahId: 114, ayahNumber: 6);
    } else {
      final next = kJuzStarts[juz];
      if (next.surahId == start.surahId) {
        end = JuzStart(surahId: next.surahId, ayahNumber: next.ayahNumber - 1);
      } else {
        // Multi-surah Juz: end is the last ayah of the previous
        // surah. We can't hardcode that here without a per-surah
        // ayahCount table, so we use a sentinel (next.surahId,
        // 999) and let the SQL `BETWEEN` clamp it. The query
        // also carries an explicit `surah_id BETWEEN start.surah
        // AND (next.surah - 1)` to keep the result scoped to the
        // Juz.
        end = JuzStart(surahId: next.surahId - 1, ayahNumber: 999);
      }
    }
    final q = select(ayahs)
      ..where(
        (a) =>
            a.surahId.isBiggerOrEqualValue(start.surahId) &
            a.surahId.isSmallerOrEqualValue(end.surahId) &
            ((a.surahId.equals(start.surahId) &
                    a.ayahNumber.isBiggerOrEqualValue(start.ayahNumber)) |
                (a.surahId.equals(end.surahId) &
                    a.ayahNumber.isSmallerOrEqualValue(end.ayahNumber)) |
                (a.surahId.isBiggerThanValue(start.surahId) &
                    a.surahId.isSmallerThanValue(end.surahId))),
      )
      ..orderBy([
        (a) => OrderingTerm.asc(a.surahId),
        (a) => OrderingTerm.asc(a.ayahNumber),
      ]);
    if (limit != null) q.limit(limit);
    return q.watch();
  }

  /// Backfill the `Ayahs.juz` column for every row whose `juz` is
  /// NULL. The Juz value is derived from the [kJuzStarts] table
  /// via [juzForAyah] — no extra data needed.
  ///
  /// Called from [AppDatabase.migration] (onCreate and onUpgrade
  /// v5 -> v6) so the column gets populated on the first run
  /// after this commit. The `WHERE juz IS NULL` clause makes the
  /// statement idempotent: re-running it is a no-op.
  Future<int> backfillJuzColumn() async {
    // We compute the Juz per row by joining the in-memory
    // [kJuzStarts] mapping onto each ayah. Implementation:
    // build a per-surah `juz` value at the SQL layer using a
    // CASE expression, and UPDATE only the NULL rows. Doing it
    // in one UPDATE keeps the cost of the migration O(N) instead
    // of O(N * DAOs) round-trips.
    //
    // We express each Juz boundary as a SQL clause: the latest
    // boundary that the row matches is the row's Juz.
    final caseClauses = StringBuffer();
    final args = <Variable<Object>>[];
    for (var i = 0; i < kJuzStarts.length; i++) {
      final start = kJuzStarts[i];
      caseClauses.write(
        'WHEN surah_id > ${start.surahId} '
        'OR (surah_id = ${start.surahId} '
        'AND ayah_number >= ${start.ayahNumber}) THEN ${i + 1} ',
      );
    }
    final updatedCount = await customUpdate(
      'UPDATE ayahs SET juz = $caseClauses'
      'WHERE juz IS NULL',
      variables: args,
      updates: {ayahs},
    );
    return updatedCount;
  }

  Future<List<Word>> getWordsForAyah(int ayahId) =>
      (select(words)
            ..where((w) => w.ayahId.equals(ayahId))
            ..orderBy([(w) => OrderingTerm.asc(w.position)]))
          .get();

  Future<int> count() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM ayahs',
      readsFrom: {ayahs},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<void> insertAyahs(List<AyahsCompanion> items) async {
    await batch((b) => b.insertAllOnConflictUpdate(ayahs, items));
  }

  /// Full-text search over Arabic ayah text using the FTS5 shadow table
  /// `ayahs_fts` (created in [AppDatabase._createFts]).
  ///
  /// The query is normalized into a `token* token*` prefix-MATCH
  /// expression so partial words still match (e.g. "رح" finds
  /// "الرحمن"). FTS5 special characters are stripped to keep the
  /// MATCH expression well-formed even with arbitrary user input.
  ///
  /// Returns up to [limit] hits, ordered by `rank()` (FTS5 bm25-like
  /// relevance) with surah/ayah order as the tie-breaker so the result
  /// is stable across calls.
  Future<List<AyahSearchHit>> searchByText(
    String query, {
    int limit = 50,
  }) async {
    final ftsQuery = buildFtsPrefixQuery(query);
    if (ftsQuery.isEmpty) return const [];
    final rows = await customSelect(
      '''
      SELECT a.id AS ayah_id,
             a.surah_id AS surah_id,
             a.ayah_number AS ayah_number,
             s.name_ar AS surah_name_ar,
             a.text_uthmani AS text_uthmani,
             a.text_normalized AS text_normalized
      FROM ayahs_fts
      INNER JOIN ayahs a ON a.id = ayahs_fts.rowid
      INNER JOIN surahs s ON s.id = a.surah_id
      WHERE ayahs_fts MATCH ?
      ORDER BY rank, a.surah_id, a.ayah_number
      LIMIT ?
      ''',
      variables: [Variable.withString(ftsQuery), Variable.withInt(limit)],
      readsFrom: {ayahs},
    ).get();
    return rows
        .map(
          (r) => AyahSearchHit(
            ayahId: r.read<int>('ayah_id'),
            surahId: r.read<int>('surah_id'),
            ayahNumber: r.read<int>('ayah_number'),
            surahNameAr: r.read<String>('surah_name_ar'),
            textUthmani: r.read<String>('text_uthmani'),
            textNormalized: r.read<String>('text_normalized'),
          ),
        )
        .toList();
  }
}
