// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reciter_dao.dart';

// ignore_for_file: type=lint
mixin _$ReciterDaoMixin on DatabaseAccessor<AppDatabase> {
  $RecitersTable get reciters => attachedDatabase.reciters;
  ReciterDaoManager get managers => ReciterDaoManager(this);
}

class ReciterDaoManager {
  final _$ReciterDaoMixin _db;
  ReciterDaoManager(this._db);
  $$RecitersTableTableManager get reciters =>
      $$RecitersTableTableManager(_db.attachedDatabase, _db.reciters);
}
