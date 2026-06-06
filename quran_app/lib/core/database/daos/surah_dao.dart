import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'surah_dao.g.dart';

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
}
