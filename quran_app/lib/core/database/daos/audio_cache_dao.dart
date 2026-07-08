import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'audio_cache_dao.g.dart';

@DriftAccessor(tables: [AudioCacheMetadata])
class AudioCacheDao extends DatabaseAccessor<AppDatabase>
    with _$AudioCacheDaoMixin {
  AudioCacheDao(super.db);

  Future<AudioCacheMetadatum?> findByKey(String reciterId, int surahId) =>
      (select(audioCacheMetadata)
            ..where(
              (r) => r.reciterId.equals(reciterId) & r.surahId.equals(surahId),
            ))
          .getSingleOrNull();

  Future<void> insert(AudioCacheMetadatum data) =>
      into(audioCacheMetadata).insertOnConflictUpdate(data);

  Future<int> touchPlayed(int id, DateTime when) =>
      (update(audioCacheMetadata)..where((r) => r.id.equals(id))).write(
        AudioCacheMetadataCompanion(lastPlayedAt: Value(when)),
      );

  /// Все записи, отсортированные по `last_played_at` (oldest first —
  /// первые кандидаты на eviction). NULL `last_played_at` идёт первым.
  Future<List<AudioCacheMetadatum>> oldestFirst({int limit = 100}) =>
      (select(audioCacheMetadata)
            ..orderBy([(r) => OrderingTerm(expression: r.lastPlayedAt)])
            ..limit(limit))
          .get();

  /// Общий размер кеша в байтах.
  Future<int> totalBytes() async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(file_size_bytes), 0) AS s FROM audio_cache_metadata',
      readsFrom: {audioCacheMetadata},
    ).getSingle();
    return row.read<int>('s');
  }

  /// Удалить запись по id (для eviction).
  Future<int> deleteById(int id) =>
      (delete(audioCacheMetadata)..where((r) => r.id.equals(id))).go();

  /// Очистить весь кеш.
  Future<int> deleteAll() => delete(audioCacheMetadata).go();

  /// Поток общего размера (для UI "X MB / Y MB").
  Stream<int> watchTotalBytes() {
    return customSelect(
      'SELECT COALESCE(SUM(file_size_bytes), 0) AS s FROM audio_cache_metadata',
      readsFrom: {audioCacheMetadata},
    ).watchSingle().map((r) => r.read<int>('s'));
  }

  /// Стрим ID ректоров, для которых скачаны **все** суры (>= [totalSurahs]
  /// MP3). Используется в picker'е для иконки «загружено» / «загрузить».
  /// Пустой Set если ни один ректор не имеет полного кеша.
  Stream<Set<String>> watchFullyCachedReciters({int totalSurahs = 114}) {
    return customSelect(
      'SELECT reciter_id FROM audio_cache_metadata '
      'GROUP BY reciter_id HAVING COUNT(DISTINCT surah_id) >= ?',
      variables: [Variable.withInt(totalSurahs)],
      readsFrom: {audioCacheMetadata},
    ).watch().map(
          (rows) => rows.map((r) => r.read<String>('reciter_id')).toSet(),
        );
  }
}
