import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'words_dao.g.dart';

@DriftAccessor(tables: [Words, Ayahs])
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
}
