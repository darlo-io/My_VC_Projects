// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'words_dao.dart';

// ignore_for_file: type=lint
mixin _$WordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SurahsTable get surahs => attachedDatabase.surahs;
  $AyahsTable get ayahs => attachedDatabase.ayahs;
  $WordsTable get words => attachedDatabase.words;
  WordsDaoManager get managers => WordsDaoManager(this);
}

class WordsDaoManager {
  final _$WordsDaoMixin _db;
  WordsDaoManager(this._db);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db.attachedDatabase, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db.attachedDatabase, _db.ayahs);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
}
