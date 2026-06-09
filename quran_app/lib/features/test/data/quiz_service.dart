import 'package:drift/drift.dart' show Variable;

import '../../../core/database/app_database.dart';
import 'quiz_session.dart';

/// Builds a [QuizSession] from a real [AppDatabase]. Picks the
/// source pool based on the user's reading history: the pool is
/// scoped to the last-read surah (so the quiz feels relevant) and
/// falls back to a random sample of 30 surahs when there's no
/// reading history yet.
class QuizService {
  QuizService(this._db);

  final AppDatabase _db;

  /// Fetch a pool of [TranslationOption]s ready to be passed to
  /// [QuizSession.fromTranslations].
  ///
  /// Strategy:
  ///   1. If we have a `LastPosition`, restrict the pool to the
  ///      last-read surah. (If the user is brand-new we fall
  ///      through to the next step.)
  ///   2. Otherwise (or if the last-read surah has no translations
  ///      in the user's language) pick 30 random surahs and union
  ///      their translations.
  ///
  /// Always restricted to the requested [languageCode] so the
  /// quiz text matches what the user sees in the reader.
  Future<List<TranslationOption>> buildPool({
    required String languageCode,
  }) async {
    final lastRow = await (_db.select(_db.lastPosition)
          ..where((p) => p.id.equals(1)))
        .getSingleOrNull();
    final surahIds = <int>{};
    if (lastRow != null) {
      surahIds.add(lastRow.surahId);
    }
    if (surahIds.isEmpty) {
      // Pick 30 random surahs. We do this in SQL rather than
      // fetching all 114 and shuffling in Dart so the test
      // fixture doesn't need to be huge.
      final rows = await _db.customSelect(
        'SELECT id FROM surahs ORDER BY RANDOM() LIMIT 30',
        readsFrom: {_db.surahs},
      ).get();
      for (final r in rows) {
        surahIds.add(r.read<int>('id'));
      }
    }
    return _fetchOptions(
      surahIds: surahIds,
      languageCode: languageCode,
    );
  }

  Future<List<TranslationOption>> _fetchOptions({
    required Set<int> surahIds,
    required String languageCode,
  }) async {
    if (surahIds.isEmpty) return const [];
    // Build a "IN (?, ?, ?)" placeholders clause for Drift.
    final placeholders = List.filled(surahIds.length, '?').join(', ');
    final rows = await _db.customSelect(
      '''
      SELECT t.ayah_id AS ayah_id,
             t.text    AS text,
             a.surah_id AS surah_id,
             a.ayah_number AS ayah_number
      FROM translations t
      INNER JOIN translators tr ON tr.id = t.translator_id
      INNER JOIN ayahs a        ON a.id = t.ayah_id
      WHERE tr.language_code = ?
        AND a.surah_id IN ($placeholders)
      ORDER BY a.surah_id, a.ayah_number
      ''',
      variables: [
        Variable.withString(languageCode),
        for (final id in surahIds) Variable.withInt(id),
      ],
      readsFrom: {_db.translations, _db.translators, _db.ayahs},
    ).get();
    return rows
        .map(
          (r) => TranslationOption(
            ayahId: r.read<int>('ayah_id'),
            surahId: r.read<int>('surah_id'),
            ayahNumber: r.read<int>('ayah_number'),
            text: r.read<String>('text'),
          ),
        )
        .toList();
  }

  /// Convenience: fetch the pool and build a [QuizSession] in one
  /// shot. Returns `null` if the pool is too small (less than
  /// [QuizSession.optionsPerQuestion] entries), in which case the
  /// screen shows the "no questions available" empty state.
  Future<QuizSession?> buildSession({
    required String languageCode,
    int questionCount = 10,
  }) async {
    final pool = await buildPool(languageCode: languageCode);
    if (pool.length < QuizSession.optionsPerQuestion) {
      return null;
    }
    return QuizSession.fromTranslations(
      pool: pool,
      questionCount: questionCount,
    );
  }
}
