// QuranComReciterDao — CRUD для [QuranComReciters] таблицы.
//
// Sprint 1.5. Таблица держит per-reciter override URL'ов Quran.com
// CDN. Static mapping через [kMp3quranToQuranCom] — primary path,
// эта таблица — для кастом-импортов и overrides.

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'quran_com_reciter_dao.g.dart';

@DriftAccessor(tables: [QuranComReciters])
class QuranComReciterDao extends DatabaseAccessor<AppDatabase>
    with _$QuranComReciterDaoMixin {
  QuranComReciterDao(super.db);

  /// Upsert по reciterId — идемпотентно, перезаписывает существующую запись.
  Future<void> upsert({
    required String reciterId,
    required int quranComId,
    required String path,
    String? style,
    required String nameLocalized,
  }) async {
    await into(quranComReciters).insertOnConflictUpdate(
      QuranComRecitersCompanion(
        reciterId: Value(reciterId),
        quranComId: Value(quranComId),
        path: Value(path),
        style: Value(style),
        nameLocalized: Value(nameLocalized),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Bulk upsert (используется при initial sync).
  Future<void> upsertAll(Iterable<QuranComReciterDaoUpsert> entries) async {
    await batch((b) {
      for (final e in entries) {
        b.insert(
          quranComReciters,
          QuranComRecitersCompanion(
            reciterId: Value(e.reciterId),
            quranComId: Value(e.quranComId),
            path: Value(e.path),
            style: Value(e.style),
            nameLocalized: Value(e.nameLocalized),
            syncedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Возвращает запись для конкретного reciterId, или null.
  Future<QuranComReciter?> getByReciterId(String reciterId) async {
    return (select(quranComReciters)..where((t) => t.reciterId.equals(reciterId)))
        .getSingleOrNull();
  }

  /// Стрим всех записей (для UI-индикации «сколько ректоров синхронизировано»).
  Stream<List<QuranComReciter>> watchAll() => select(quranComReciters).watch();

  /// TTL-проверка: true если запись старше [maxAgeDays] или отсутствует.
  Future<bool> isStale(String reciterId, {int maxAgeDays = 7}) async {
    final row = await getByReciterId(reciterId);
    if (row == null) return true;
    final age = DateTime.now().difference(row.syncedAt);
    return age.inDays >= maxAgeDays;
  }

  /// Bulk-стирание (для тестов и admin-tools).
  Future<int> deleteAll() =>
      (delete(quranComReciters)).go();
}

/// Helper-класс для batch-inserts (избегаем прямого Companion для bulk).
class QuranComReciterDaoUpsert {
  const QuranComReciterDaoUpsert({
    required this.reciterId,
    required this.quranComId,
    required this.path,
    this.style,
    required this.nameLocalized,
  });

  final String reciterId;
  final int quranComId;
  final String path;
  final String? style;
  final String nameLocalized;
}
