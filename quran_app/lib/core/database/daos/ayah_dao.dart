import 'package:drift/drift.dart';

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
  /// `null` if the combination doesn't exist (e.g. ayah number
  /// out of range, or surahId doesn't exist in the seed).
  Future<Ayah?> getBySurahAndNumber(int surahId, int ayahNumber) =>
      (select(ayahs)
            ..where(
              (a) => a.surahId.equals(surahId) &
                  a.ayahNumber.equals(ayahNumber),
            ))
          .getSingleOrNull();

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
