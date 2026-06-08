// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'words_dao.dart';

// ignore_for_file: type=lint
mixin _$WordsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WordsTable get words => attachedDatabase.words;
  $AyahsTable get ayahs => attachedDatabase.ayahs;
  WordsDaoManager get managers => WordsDaoManager(this);
}

class WordsDaoManager {
  final _$WordsDaoMixin _db;
  WordsDaoManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db.attachedDatabase, _db.ayahs);
}
