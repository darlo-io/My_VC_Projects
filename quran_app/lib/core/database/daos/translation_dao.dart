import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'translation_dao.g.dart';

class TranslationRow {
  const TranslationRow({
    required this.ayahId,
    required this.text,
  });

  final int ayahId;
  final String text;
}

/// A translation hit enriched with the surah/ayah coordinates so the
/// search-result UI can deep-link into the reader. Same idea as
/// [AyahSearchHit] but carries the translation text instead of the
/// Arabic.
class TranslationSearchHit {
  const TranslationSearchHit({
    required this.ayahId,
    required this.surahId,
    required this.ayahNumber,
    required this.surahNameAr,
    required this.text,
    required this.translatorName,
  });

  final int ayahId;
  final int surahId;
  final int ayahNumber;
  final String surahNameAr;
  final String text;
  final String translatorName;
}

@DriftAccessor(tables: [Translations, Translators, Ayahs, Surahs])
class TranslationDao extends DatabaseAccessor<AppDatabase>
    with _$TranslationDaoMixin {
  TranslationDao(super.db);

  /// Возвращает переводы аятов конкретной суры на конкретном языке.
  Future<List<TranslationRow>> getForSurah({
    required int surahId,
    required String languageCode,
  }) async {
    final rows = await customSelect(
      '''
      SELECT t.ayah_id AS ayah_id, t.text AS text
      FROM translations t
      INNER JOIN translators tr ON tr.id = t.translator_id
      INNER JOIN ayahs a ON a.id = t.ayah_id
      WHERE a.surah_id = ? AND tr.language_code = ?
      ORDER BY a.ayah_number
      ''',
      variables: [Variable.withInt(surahId), Variable.withString(languageCode)],
      readsFrom: {translations, translators, ayahs},
    ).get();
    return rows
        .map(
          (r) => TranslationRow(
            ayahId: r.read<int>('ayah_id'),
            text: r.read<String>('text'),
          ),
        )
        .toList();
  }

  /// Full-text search over translated ayah text using the FTS5 shadow
  /// table `translations_fts`, restricted to translators in
  /// [languageCode] (e.g. `'en'`, `'ru'`).
  ///
  /// Mirrors [AyahDao.searchByText]: empty/invalid queries return
  /// `const []`. Results are ordered by FTS5 rank with surah/ayah
  /// as the tie-breaker.
  Future<List<TranslationSearchHit>> search({
    required String query,
    required String languageCode,
    int limit = 50,
  }) async {
    final ftsQuery = _toTranslationFtsQuery(query);
    if (ftsQuery.isEmpty) return const [];
    final rows = await customSelect(
      '''
      SELECT a.id AS ayah_id,
             a.surah_id AS surah_id,
             a.ayah_number AS ayah_number,
             s.name_ar AS surah_name_ar,
             t.text AS text,
             tr.name AS translator_name
      FROM translations_fts
      INNER JOIN translations t ON t.id = translations_fts.rowid
      INNER JOIN translators tr ON tr.id = t.translator_id
      INNER JOIN ayahs a ON a.id = t.ayah_id
      INNER JOIN surahs s ON s.id = a.surah_id
      WHERE translations_fts MATCH ?
        AND tr.language_code = ?
      ORDER BY rank, a.surah_id, a.ayah_number
      LIMIT ?
      ''',
      variables: [
        Variable.withString(ftsQuery),
        Variable.withString(languageCode),
        Variable.withInt(limit),
      ],
      readsFrom: {translations},
    ).get();
    return rows
        .map(
          (r) => TranslationSearchHit(
            ayahId: r.read<int>('ayah_id'),
            surahId: r.read<int>('surah_id'),
            ayahNumber: r.read<int>('ayah_number'),
            surahNameAr: r.read<String>('surah_name_ar'),
            text: r.read<String>('text'),
            translatorName: r.read<String>('translator_name'),
          ),
        )
        .toList();
  }

  Future<void> insertTranslators(List<TranslatorsCompanion> items) async {
    await batch((b) => b.insertAllOnConflictUpdate(translators, items));
  }

  Future<void> insertTranslations(List<TranslationsCompanion> items) async {
    await batch((b) => b.insertAllOnConflictUpdate(translations, items));
  }
}

/// Same normalization as [AyahDao._toFtsPrefixQuery] but kept private
/// here to avoid leaking the helper into the public API of
/// [AyahDao]. The implementation is intentionally identical so that
/// search behaviour is consistent across the Arabic and translation
/// corpora.
String _toTranslationFtsQuery(String raw) {
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
