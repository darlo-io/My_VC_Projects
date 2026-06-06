import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'ayah_dao.g.dart';

@DriftAccessor(tables: [Ayahs, Words])
class AyahDao extends DatabaseAccessor<AppDatabase> with _$AyahDaoMixin {
  AyahDao(super.db);

  Stream<List<Ayah>> watchBySurah(int surahId) =>
      (select(ayahs)
            ..where((a) => a.surahId.equals(surahId))
            ..orderBy([(a) => OrderingTerm.asc(a.ayahNumber)]))
          .watch();

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
}
