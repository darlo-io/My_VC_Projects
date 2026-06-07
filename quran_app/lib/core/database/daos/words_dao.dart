import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'words_dao.g.dart';

@DriftAccessor(tables: [Words, WordTimings])
class WordsDao extends DatabaseAccessor<AppDatabase> with _$WordsDaoMixin {
  WordsDao(super.db);

  /// Слова одной суры, отсортированные по (ayah_id, position).
  Stream<List<Word>> watchBySurah(int surahId) {
    final query = select(words).join([
      innerJoin(ayahs, ayahs.id.equalsExp(words.ayahId)),
    ])
      ..where(ayahs.surahId.equals(surahId))
      ..orderBy([
        OrderingTerm.asc(ayahs.ayahNumber),
        OrderingTerm.asc(words.position),
      ]);
    return query.watch().map(
          (rows) => rows.map((r) => r.readTable(words)).toList(),
        );
  }

  /// Слова одного аята.
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
}
