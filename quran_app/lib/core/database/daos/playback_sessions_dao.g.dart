// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$PlaybackSessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PlaybackSessionsTable get playbackSessions =>
      attachedDatabase.playbackSessions;
  PlaybackSessionsDaoManager get managers => PlaybackSessionsDaoManager(this);
}

class PlaybackSessionsDaoManager {
  final _$PlaybackSessionsDaoMixin _db;
  PlaybackSessionsDaoManager(this._db);
  $$PlaybackSessionsTableTableManager get playbackSessions =>
      $$PlaybackSessionsTableTableManager(
        _db.attachedDatabase,
        _db.playbackSessions,
      );
}
