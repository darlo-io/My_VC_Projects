import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'surah_dao.g.dart';

/// Projection used by [SurahDao.searchByText]. Returns just the
/// fields the search-result UI needs; callers that need the full
/// row can follow up with [SurahDao.getById].
class SurahSearchHit {
  const SurahSearchHit({
    required this.surahId,
    required this.nameAr,
    required this.nameEn,
    required this.nameTransliteration,
  });

  final int surahId;
  final String nameAr;
  final String nameEn;
  final String nameTransliteration;
}

@DriftAccessor(tables: [Surahs])
class SurahDao extends DatabaseAccessor<AppDatabase> with _$SurahDaoMixin {
  SurahDao(super.db);

  Future<List<Surah>> getAll() => select(surahs).get();

  Stream<List<Surah>> watchAll() => select(surahs).watch();

  Future<Surah?> getById(int id) =>
      (select(surahs)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<void> insertAll(List<SurahsCompanion> items) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(surahs, items);
    });
  }

  Future<int> count() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM surahs',
      readsFrom: {surahs},
    ).getSingle();
    return row.read<int>('c');
  }

  /// Substring search over the three name columns of [Surahs]. Hits
  /// match if `query` is a prefix of `name_transliteration`,
  /// `name_en`, or `name_ar` (after `LOWER()` for the Latin
  /// columns). Numeric queries also match against the surah id.
  ///
  /// The query is not FTS5-backed (the `surahs` table is too small
  /// at 114 rows to benefit from a shadow table), but it still
  /// strips FTS5 reserved characters from the input so a stray
  /// `*` or `"` in user text doesn't make the `LIKE` pattern
  /// misbehave.
  Future<List<SurahSearchHit>> searchByText(
    String query, {
    int limit = 30,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    // Strip FTS5 operators the same way [buildFtsPrefixQuery] does,
    // to keep one source of truth for "what characters are safe in
    // a user-typed query". The leading-% pattern lets mid-string
    // matches work too (e.g. "atih" still finds "Al-Fatiha").
    const banned = {'"', '\'', '(', ')', '*', ':', '^', '-', '+', '.', ',', ';'};
    final safe = q
        .split('')
        .where((c) => !banned.contains(c))
        .join();
    if (safe.isEmpty) return const [];
    final lowerSafe = safe.toLowerCase();
    final like = '%$lowerSafe%';
    final arabicLike = '%$safe%';
    final idMatch = int.tryParse(safe);
    final rows = await customSelect(
      '''
      SELECT id, name_ar, name_en, name_transliteration
      FROM surahs
      WHERE LOWER(name_transliteration) LIKE ?
         OR LOWER(name_en) LIKE ?
         OR name_ar LIKE ?
         ${idMatch != null ? 'OR id = ?' : ''}
      ORDER BY id
      LIMIT ?
      ''',
      variables: [
        Variable.withString(like),
        Variable.withString(like),
        Variable.withString(arabicLike),
        if (idMatch != null) Variable.withInt(idMatch),
        Variable.withInt(limit),
      ],
      readsFrom: {surahs},
    ).get();
    return rows
        .map(
          (r) => SurahSearchHit(
            surahId: r.read<int>('id'),
            nameAr: r.read<String>('name_ar'),
            nameEn: r.read<String>('name_en'),
            nameTransliteration: r.read<String>('name_transliteration'),
          ),
        )
        .toList();
  }
}
