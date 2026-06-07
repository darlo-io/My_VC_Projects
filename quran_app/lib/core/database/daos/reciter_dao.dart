import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'reciter_dao.g.dart';

@DriftAccessor(tables: [Reciters])
class ReciterDao extends DatabaseAccessor<AppDatabase>
    with _$ReciterDaoMixin {
  ReciterDao(super.db);

  Stream<List<Reciter>> watchAll() =>
      (select(reciters)..orderBy([(r) => OrderingTerm.asc(r.nameEn)]))
          .watch();

  Future<List<Reciter>> getAll() =>
      (select(reciters)..orderBy([(r) => OrderingTerm.asc(r.nameEn)])).get();

  Future<Reciter?> getById(String id) =>
      (select(reciters)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<int> count() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM reciters',
      readsFrom: {reciters},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<void> insertAll(List<RecitersCompanion> items) async {
    await batch((b) => b.insertAllOnConflictUpdate(reciters, items));
  }
}
