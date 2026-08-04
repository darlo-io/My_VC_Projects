import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'reciter_dao.g.dart';

@DriftAccessor(tables: [Reciters])
class ReciterDao extends DatabaseAccessor<AppDatabase>
    with _$ReciterDaoMixin {
  ReciterDao(super.db);

  Stream<List<Reciter>> watchAll() =>
      (select(reciters)..orderBy([(r) => OrderingTerm.asc(r.nameAr)])).watch();

  Stream<List<Reciter>> watchFavorites() =>
      (select(reciters)
            ..where((r) => r.isFavorite.equals(true))
            ..orderBy([(r) => OrderingTerm.asc(r.nameAr)]))
          .watch();

  /// Сортировка: сначала избранные, потом всё остальное по nameAr.
  Stream<List<Reciter>> watchAllWithFavoritesFirst() =>
      (select(reciters)..orderBy([
        (r) => OrderingTerm.desc(r.isFavorite),
        (r) => OrderingTerm.asc(r.nameAr),
      ])).watch();

  Future<List<Reciter>> getAll() =>
      (select(reciters)..orderBy([(r) => OrderingTerm.asc(r.nameAr)])).get();

  Future<Reciter?> getById(String id) =>
      (select(reciters)..where((r) => r.id.equals(id))).getSingleOrNull();

  /// Установить/снять отметку избранного.
  Future<void> setFavorite(String reciterId, bool isFavorite) async {
    await (update(reciters)..where((r) => r.id.equals(reciterId))).write(
      RecitersCompanion(isFavorite: Value(isFavorite)),
    );
  }

  Future<int> count() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM reciters',
      readsFrom: {reciters},
    ).getSingle();
    return row.read<int>('c');
  }

  /// Возвращает `MAX(mp3quran_cached_at)` — когда последний раз был
  /// синхронизирован весь список с mp3quran.net API. `null` если ни
  /// одного ректора с mp3quran-метаданными в БД нет (т.е. после
  /// миграции нужно сразу синхронизировать).
  ///
  /// Используется в [RecitersSyncService.maybeSync] для определения,
  /// устарел ли кеш (см. `mp3quranCachedAt` в [Reciters]).
  Future<DateTime?> latestMp3quranSync() async {
    final row = await customSelect(
      'SELECT MAX(mp3quran_cached_at) AS t FROM reciters '
      'WHERE mp3quran_cached_at IS NOT NULL',
      readsFrom: {reciters},
    ).getSingleOrNull();
    final t = row?.read<int?>('t');
    if (t == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(t);
  }

  /// Кол-во ректоров без mp3quran-метаданных (включая тех, у которых
  /// есть `mp3quran_id == null`). Используется в
  /// [RecitersSyncService.maybeSync] — даже если `latestMp3quranSync`
  /// свежий, нужно дотянуть отсутствующих.
  Future<int> countRecitersWithoutMp3quranInfo() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS c FROM reciters '
      'WHERE mp3quran_id IS NULL '
      'OR mp3quran_server IS NULL',
      readsFrom: {reciters},
    ).getSingle();
    return row.read<int>('c');
  }

  Future<void> insertAll(List<RecitersCompanion> items) async {
    await batch((b) => b.insertAllOnConflictUpdate(reciters, items));
  }

  /// Заполняет/перезаписывает mp3quran-метаданные для существующего
  /// ректора (используется при [RecitersRepository.ensureSeeded]).
  Future<void> updateMp3quranInfo({
    required String reciterId,
    required int mp3quranId,
    required int moshafId,
    required String server,
    required String rewaya,
    required int surahTotal,
  }) async {
    await (update(reciters)..where((r) => r.id.equals(reciterId))).write(
      RecitersCompanion(
        mp3quranId: Value(mp3quranId),
        mp3quranServer: Value(server),
        mp3quranMoshafId: Value(moshafId),
        mp3quranSurahTotal: Value(surahTotal),
        mp3quranRewaya: Value(rewaya),
        mp3quranCachedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Insert или update — для синхронизации из MP3Quran API.
  /// Использует `ON CONFLICT(id) DO UPDATE` через
  /// [insertAllOnConflictUpdate] пакета.
  Future<void> upsertWithMp3quran({
    required String reciterId,
    required String slug,
    required String nameAr,
    required String nameEn,
    required String style,
    required int mp3quranId,
    required int moshafId,
    required String server,
    required String rewaya,
    required int surahTotal,
    required int cachedAt,
  }) async {
    await into(reciters).insertOnConflictUpdate(
      RecitersCompanion.insert(
        id: reciterId,
        slug: slug,
        nameAr: nameAr,
        nameEn: Value(nameEn),
        style: style,
        mp3quranId: Value(mp3quranId),
        mp3quranMoshafId: Value(moshafId),
        mp3quranServer: Value(server),
        mp3quranSurahTotal: Value(surahTotal),
        mp3quranRewaya: Value(rewaya),
        mp3quranCachedAt: Value(cachedAt),
      ),
    );
  }

  /// Multi-locale версия: nullable nameRu, nameEn, moshafType.
  /// Использует [RecitersRepository.syncFromApi].
  Future<void> upsertWithMp3quranMultiLocale({
    required String reciterId,
    required String slug,
    required String nameAr,
    String? nameRu,
    String? nameEn,
    required String style,
    required int mp3quranId,
    required int moshafId,
    required String server,
    required String rewaya,
    int? moshafType,
    required int surahTotal,
    required int cachedAt,
  }) async {
    // Round 9.6 (code review #C9): при sync из API mp3quran.net
    // вызывался `insertOnConflictUpdate(RecitersCompanion.insert(...))`,
    // который в ветке `ON CONFLICT DO UPDATE` перезаписывал
    // ВСЕ колонки — включая user-edited `isFavorite` (default 0).
    // Это означало, что sync стирал отметку «избранное» каждый
    // раз. Теперь используется кастомное обновление,
    // исключающее user-state колонки (`isFavorite`).
    await customInsert(
      '''
      INSERT INTO reciters (
        id, slug, name_ar, name_ru, name_en, style,
        mp3quran_id, mp3quran_moshaf_id, mp3quran_server,
        mp3quran_surah_total, mp3quran_rewaya, mp3quran_moshaf_type,
        mp3quran_cached_at, mp3quran_is_downloaded
      ) VALUES (
        ?, ?, ?, ?, ?, ?,
        ?, ?, ?,
        ?, ?, ?,
        ?, ?
      )
      ON CONFLICT (id) DO UPDATE SET
        slug = excluded.slug,
        name_ar = excluded.name_ar,
        name_ru = excluded.name_ru,
        name_en = excluded.name_en,
        style = excluded.style,
        mp3quran_id = excluded.mp3quran_id,
        mp3quran_moshaf_id = excluded.mp3quran_moshaf_id,
        mp3quran_server = excluded.mp3quran_server,
        mp3quran_surah_total = excluded.mp3quran_surah_total,
        mp3quran_rewaya = excluded.mp3quran_rewaya,
        mp3quran_moshaf_type = excluded.mp3quran_moshaf_type,
        mp3quran_cached_at = excluded.mp3quran_cached_at
        -- is_favorite НЕ изменяется (user-state)
      ''',
      variables: [
        Variable.withString(reciterId),
        Variable.withString(slug),
        Variable.withString(nameAr),
        if (nameRu != null) Variable.withString(nameRu),
        if (nameEn != null) Variable.withString(nameEn),
        Variable.withString(style),
        Variable.withInt(mp3quranId),
        Variable.withInt(moshafId),
        Variable.withString(server),
        Variable.withInt(surahTotal),
        Variable.withString(rewaya),
        if (moshafType != null) Variable.withInt(moshafType),
        Variable.withInt(cachedAt),
        Variable.withInt(0), // mp3quran_is_downloaded default
      ],
    );
  }

  /// Обновляет только [nameRu] для одной записи (используется
  /// в [RecitersRepository.applyNameOverrides] для fix-up).
  Future<int> updateNameRu(String id, String newNameRu) {
    return (update(reciters)..where((r) => r.id.equals(id))).write(
      RecitersCompanion(nameRu: Value(newNameRu)),
    );
  }

  /// Round 9.6 (code review #C3): batch-update `nameRu` для многих
  /// записей в **одной DB-транзакции**. Возвращает количество
  /// обновлённых строк. Раньше [RecitersRepository.applyNameOverrides]
  /// делал N отдельных `update().write()` = N+1 round-trip-ов в
  /// SQLite. Для 240 ректоров это = 240 round-trip-ов (≈ 100ms на
  /// одном устройстве). Теперь — 1 batch.
  ///
  /// `entries` — список `(id, newNameRu)`. Пустой список — no-op
  /// (возвращает 0 без открытия транзакции).
  Future<int> updateNameRuBatch(
    List<({String id, String newNameRu})> entries,
  ) async {
    if (entries.isEmpty) return 0;
    return transaction(() async {
      var updated = 0;
      for (final e in entries) {
        final n = await (update(reciters)
              ..where((r) => r.id.equals(e.id)))
            .write(RecitersCompanion(nameRu: Value(e.newNameRu)));
        updated += n;
      }
      return updated;
    });
  }
}
