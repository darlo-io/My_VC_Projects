// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ayah_dao.dart';

// ignore_for_file: type=lint
mixin _$AyahDaoMixin on DatabaseAccessor<AppDatabase> {
  $SurahsTable get surahs => attachedDatabase.surahs;
  $AyahsTable get ayahs => attachedDatabase.ayahs;
  $WordsTable get words => attachedDatabase.words;
  AyahDaoManager get managers => AyahDaoManager(this);
}

class AyahDaoManager {
  final _$AyahDaoMixin _db;
  AyahDaoManager(this._db);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db.attachedDatabase, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db.attachedDatabase, _db.ayahs);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
}
