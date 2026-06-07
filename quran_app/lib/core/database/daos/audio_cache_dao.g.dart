// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$AudioCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $AudioCacheMetadataTable get audioCacheMetadata =>
      attachedDatabase.audioCacheMetadata;
  AudioCacheDaoManager get managers => AudioCacheDaoManager(this);
}

class AudioCacheDaoManager {
  final _$AudioCacheDaoMixin _db;
  AudioCacheDaoManager(this._db);
  $$AudioCacheMetadataTableTableManager get audioCacheMetadata =>
      $$AudioCacheMetadataTableTableManager(
        _db.attachedDatabase,
        _db.audioCacheMetadata,
      );
}
