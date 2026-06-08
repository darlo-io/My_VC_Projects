import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'words_dao.g.dart';

/// Lightweight projection used by [WordsDao.search] /
/// [WordsDao.searchByRoot]. Carries the minimum data the result row
/// UI needs to render a tap target and deep-link into the reader
/// without a second round-trip to load the full Word + its Ayah.
class WordSearchHit {
  const WordSearchHit({
    required this.wordId,
    required this.surahId,
    required this.ayahNumber,
    required this.position,
    required this.arabic,
    required this.normalized,
    required this.translation,
    required this.lemma,
    required this.root,
  });

  final int wordId;
  final int surahId;
  final int ayahNumber;
  final int position;
  final String arabic;
  final String normalized;
  final String? translation;
  final String? lemma;
  final String? root;
}

@DriftAccessor(tables: [Words, Ayahs, Surahs])
class WordsDao extends DatabaseAccessor<AppDatabase> with _$WordsDaoMixin {
  WordsDao(super.db);

  /// Слова одного аята, отсортированные по position.
  Future<List<Word>> getByAyah(int ayahId) =>
      (select(words)
            ..where((w) => w.ayahId.equals(ayahId))
            ..orderBy([(w) => OrderingTerm.asc(w.position)]))
          .get();

  Future<int> count() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM words',
      readsFrom: {words},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<void> insertAll(List<WordsCompanion> items) async {
    await batch((b) => b.insertAllOnConflictUpdate(words, items));
  }

  /// Full-text search over the word dictionary using the FTS5 shadow
  /// table `words_fts` (created in [AppDatabase._createFts]). Searches
  /// across Arabic, normalized, translation, lemma, and root columns
  /// in a single MATCH expression.
  ///
  /// The query is normalized into a `token* token*` prefix-MATCH so
  /// partial Arabic roots still match (e.g. `رحم` finds `الرحمن`).
  /// FTS5 reserved characters are stripped, see [_toFtsPrefixQuery].
  Future<List<WordSearchHit>> search(String query, {int limit = 30}) async {
    final ftsQuery = _toFtsPrefixQuery(query);
    if (ftsQuery.isEmpty) return const [];
    final rows = await customSelect(
      '''
      SELECT w.id AS word_id,
             a.surah_id AS surah_id,
             a.ayah_number AS ayah_number,
             w.position AS position,
             w.arabic AS arabic,
             w.normalized AS normalized,
             w.translation AS translation,
             w.lemma AS lemma,
             w.root AS root
      FROM words_fts
      INNER JOIN words w ON w.id = words_fts.rowid
      INNER JOIN ayahs a ON a.id = w.ayah_id
      WHERE words_fts MATCH ?
      ORDER BY rank, a.surah_id, a.ayah_number, w.position
      LIMIT ?
      ''',
      variables: [Variable.withString(ftsQuery), Variable.withInt(limit)],
      readsFrom: {words},
    ).get();
    return rows.map(_rowToHit).toList();
  }

  /// Exact-match lookup by Arabic root. Faster than [search] (no FTS
  /// ranking, just a `LIKE` over the indexed `root` column) and
  /// preferred for the "Other words with the same root" section in
  /// the learning card: we already know the exact root string.
  ///
  /// [excludeWordId] lets the caller drop the seed word from the
  /// result list so the user doesn't see their starting word echoed
  /// back as a "related" result.
  Future<List<WordSearchHit>> searchByRoot(
    String root, {
    int limit = 20,
    int? excludeWordId,
  }) async {
    if (root.isEmpty) return const [];
    final pattern = '%$root%';
    final query = customSelect(
      '''
      SELECT w.id AS word_id,
             a.surah_id AS surah_id,
             a.ayah_number AS ayah_number,
             w.position AS position,
             w.arabic AS arabic,
             w.normalized AS normalized,
             w.translation AS translation,
             w.lemma AS lemma,
             w.root AS root
      FROM words w
      INNER JOIN ayahs a ON a.id = w.ayah_id
      WHERE w.root LIKE ?
      ${excludeWordId != null ? 'AND w.id != ?' : ''}
      ORDER BY a.surah_id, a.ayah_number, w.position
      LIMIT ?
      ''',
      variables: [
        Variable.withString(pattern),
        if (excludeWordId != null) Variable.withInt(excludeWordId),
        Variable.withInt(limit),
      ],
      readsFrom: {words},
    );
    final rows = await query.get();
    return rows.map(_rowToHit).toList();
  }

  WordSearchHit _rowToHit(QueryRow r) => WordSearchHit(
        wordId: r.read<int>('word_id'),
        surahId: r.read<int>('surah_id'),
        ayahNumber: r.read<int>('ayah_number'),
        position: r.read<int>('position'),
        arabic: r.read<String>('arabic'),
        normalized: r.read<String>('normalized'),
        translation: r.read<String?>('translation'),
        lemma: r.read<String?>('lemma'),
        root: r.read<String?>('root'),
      );
}

/// Normalize a free-form user query into a safe FTS5 prefix-MATCH
/// expression. Same rules as
/// [AyahDao._toFtsPrefixQuery] — strip FTS5 operators, emit each
/// remaining token as `token*` so partial words still match.
String _toFtsPrefixQuery(String raw) {
  const banned = {'"', '\'', '(', ')', '*', ':', '^', '-', '+', '.', ',', ';'};
  final tokens = raw
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .map((t) => t.split('').where((c) => !banned.contains(c)).join())
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return '';
  return tokens.map((t) => '$t*').join(' ');
}
