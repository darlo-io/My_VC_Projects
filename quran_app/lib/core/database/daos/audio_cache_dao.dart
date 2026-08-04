import 'dart:developer' as developer;

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'audio_cache_dao.g.dart';

@DriftAccessor(tables: [AudioCacheMetadata])
class AudioCacheDao extends DatabaseAccessor<AppDatabase>
    with _$AudioCacheDaoMixin {
  AudioCacheDao(super.db);

  Future<AudioCacheMetadatum?> findByKey(String reciterId, int surahId) async {
    final row = await (select(audioCacheMetadata)
          ..where(
            (r) => r.reciterId.equals(reciterId) & r.surahId.equals(surahId),
          ))
        .getSingleOrNull();
    // ignore: avoid_print
      developer.log(
        'audio_cache.findByKey($reciterId, $surahId) = ${row?.id}',
        name: 'AudioCacheDao',
      );
    return row;
  }

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
  ///
  /// Под капотом: `customSelect` с `SELECT reciter_id AS r ... GROUP BY
  /// reciter_id HAVING COUNT(DISTINCT surah_id) >= ?`. Возвращает строки
  /// с одной колонкой `r` (string), маппим в Set.
  ///
  /// Исторически баг был из-за column alias'а `AS reciter_id` — Drift
  /// мапил её как `reciter_id` напрямую, а не `r`, поэтому
  /// `r.read<String>('r')` возвращал null. Сейчас alias'а нет —
  /// читаем напрямую по column name (он без AS = column name из SQL).
  Stream<Set<String>> watchFullyCachedReciters({int totalSurahs = 114}) {
    return customSelect(
      'SELECT reciter_id, COUNT(DISTINCT surah_id) AS cnt '
      'FROM audio_cache_metadata '
      'GROUP BY reciter_id '
      'HAVING COUNT(DISTINCT surah_id) >= ?',
      variables: [Variable.withInt(totalSurahs)],
      readsFrom: {audioCacheMetadata},
    ).watch().map((rows) {
      // ignore: avoid_print
      developer.log(
        'audio_cache.watchFullyCachedReciters fired with ${rows.length} rows: '
        '${rows.map((r) => r.read<String>('reciter_id')).toList()}',
        name: 'AudioCacheDao',
      );
      return rows
          .map((r) => r.read<String>('reciter_id'))
          .cast<String>()
          .toSet();
    });
  }

  /// True если сура [surahId] для ректора [reciterId] уже скачана
  /// и её метаданные записаны в `audio_cache_metadata`. Используется
  /// в prefetch'е для пропуска уже закешированных файлов.
  Future<bool> isCached({required String reciterId, required int surahId}) async {
    // Сначала замерим TOTAL — если все запросы возвращают одинаковое
    // число, значит WHERE игнорируется.
    final total = await customSelect(
      'SELECT COUNT(*) AS c FROM audio_cache_metadata',
      readsFrom: {audioCacheMetadata},
    ).getSingle();
    final totalCount = total.read<int>('c');

    // Теперь с WHERE.
    final row = await customSelect(
      'SELECT COUNT(*) AS cnt FROM audio_cache_metadata '
      'WHERE reciter_id = ? AND surah_id = ?',
      variables: [Variable.withString(reciterId), Variable.withInt(surahId)],
      readsFrom: {audioCacheMetadata},
    ).getSingle();
    final n = row.read<int>('cnt');
    // ignore: avoid_print
    developer.log(
      'audio_cache.isCached($reciterId, $surahId) raw cnt=$n total=$totalCount',
      name: 'AudioCacheDao',
    );
    return n > 0;
  }

  /// `INSERT OR REPLACE` через raw SQL.
  ///
  /// Заменил `into(audioCacheMetadata).insertOnConflictUpdate(data)`
  /// с `data.id: 0` — он не работал под параллельным prefetch'ом:
  /// SQLite `AUTOINCREMENT` трактует 0 как литерал 0 (а не NULL/auto)
  /// и второй параллельный INSERT для другого (reciter_id, surah_id)
  /// мог конфликтовать с уже-вставленным id=0 (PK = id, autoIncrement
  /// накладывает дополнительные ограничения). В итоге 0 строк в БД
  /// при 100+ файлах на диске.
  ///
  /// `INSERT OR REPLACE` решает:
  ///   1) На конфликте UNIQUE(reciter_id, surah_id) SQLite сам
  ///      удалит старую строку и вставит новую — никаких manual
  ///      `id` или autoIncrement-quirks.
  ///   2) Атомарно, без гонок с другими writers.
  ///   3) Работает под `BEGIN IMMEDIATE`-транзакцией для in-flight
  ///      serializability.
  Future<void> upsertCacheEntry({
    required String reciterId,
    required int surahId,
    required String filePath,
    required int fileSizeBytes,
    DateTime? downloadedAt,
    DateTime? lastPlayedAt,
  }) {
    final now = DateTime.now();
    return customInsert(
      'INSERT OR REPLACE INTO audio_cache_metadata '
      '(reciter_id, surah_id, file_path, file_size_bytes, '
      ' downloaded_at, last_played_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        Variable.withString(reciterId),
        Variable.withInt(surahId),
        Variable.withString(filePath),
        Variable.withInt(fileSizeBytes),
        Variable.withDateTime(downloadedAt ?? now),
        Variable.withDateTime(lastPlayedAt ?? now),
      ],
      updates: {audioCacheMetadata},
    );
  }
}
