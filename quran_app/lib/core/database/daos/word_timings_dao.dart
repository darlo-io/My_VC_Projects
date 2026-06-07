import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'word_timings_dao.g.dart';

class WordTimingRow {
  const WordTimingRow({
    required this.wordId,
    required this.startMs,
    required this.endMs,
  });

  final int wordId;
  final int startMs;
  final int endMs;
}

@DriftAccessor(tables: [WordTimings, Words])
class WordTimingsDao extends DatabaseAccessor<AppDatabase>
    with _$WordTimingsDaoMixin {
  WordTimingsDao(super.db);

  /// Тайминги всех слов аята для указанного ректора. JOIN'ит
  /// word_timings с words, фильтрует по surah+ayah и сортирует по position.
  Stream<List<WordTimingRow>> watchForAyah({
    required int ayahId,
    required String reciterId,
  }) {
    final query = select(wordTimings).join([
      innerJoin(words, words.id.equalsExp(wordTimings.wordId)),
    ])
      ..where(
        wordTimings.reciterId.equals(reciterId) & words.ayahId.equals(ayahId),
      )
      ..orderBy([OrderingTerm.asc(words.position)]);
    return query.watch().map(
          (rows) => rows
              .map(
                (r) => WordTimingRow(
                  wordId: r.readTable(wordTimings).wordId,
                  startMs: r.readTable(wordTimings).startMs,
                  endMs: r.readTable(wordTimings).endMs,
                ),
              )
              .toList(),
        );
  }

  /// Тайминги для одной суры целиком (для batched batch-load).
  Future<List<WordTimingRow>> getForSurah({
    required int surahId,
    required String reciterId,
  }) async {
    final rows = await customSelect(
      '''
      SELECT wt.word_id AS word_id, wt.start_ms AS start_ms, wt.end_ms AS end_ms
      FROM word_timings wt
      INNER JOIN words w ON w.id = wt.word_id
      INNER JOIN ayahs a ON a.id = w.ayah_id
      WHERE wt.reciter_id = ? AND a.surah_id = ?
      ORDER BY a.ayah_number, w.position
      ''',
      variables: [
        Variable.withString(reciterId),
        Variable.withInt(surahId),
      ],
      readsFrom: {wordTimings, words, ayahs},
    ).get();
    return rows
        .map(
          (r) => WordTimingRow(
            wordId: r.read<int>('word_id'),
            startMs: r.read<int>('start_ms'),
            endMs: r.read<int>('end_ms'),
          ),
        )
        .toList();
  }

  Future<int> count() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM word_timings',
      readsFrom: {wordTimings},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<void> insertAll(List<WordTimingsCompanion> items) async {
    await batch((b) => b.insertAllOnConflictUpdate(wordTimings, items));
  }
}
