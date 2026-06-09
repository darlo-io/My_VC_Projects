// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_dao.dart';

// ignore_for_file: type=lint
mixin _$PositionDaoMixin on DatabaseAccessor<AppDatabase> {
  $LastPositionTable get lastPosition => attachedDatabase.lastPosition;
  $ReadingHistoryTable get readingHistory => attachedDatabase.readingHistory;
  $SurahsTable get surahs => attachedDatabase.surahs;
  $AyahsTable get ayahs => attachedDatabase.ayahs;
  PositionDaoManager get managers => PositionDaoManager(this);
}

class PositionDaoManager {
  final _$PositionDaoMixin _db;
  PositionDaoManager(this._db);
  $$LastPositionTableTableManager get lastPosition =>
      $$LastPositionTableTableManager(_db.attachedDatabase, _db.lastPosition);
  $$ReadingHistoryTableTableManager get readingHistory =>
      $$ReadingHistoryTableTableManager(
        _db.attachedDatabase,
        _db.readingHistory,
      );
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db.attachedDatabase, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db.attachedDatabase, _db.ayahs);
}
