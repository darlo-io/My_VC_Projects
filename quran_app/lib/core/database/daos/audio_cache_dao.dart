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
}
