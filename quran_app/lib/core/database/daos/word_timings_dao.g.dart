// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_timings_dao.dart';

// ignore_for_file: type=lint
mixin _$WordTimingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WordTimingsTable get wordTimings => attachedDatabase.wordTimings;
  $WordsTable get words => attachedDatabase.words;
  $AyahsTable get ayahs => attachedDatabase.ayahs;
  WordTimingsDaoManager get managers => WordTimingsDaoManager(this);
}

class WordTimingsDaoManager {
  final _$WordTimingsDaoMixin _db;
  WordTimingsDaoManager(this._db);
  $$WordTimingsTableTableManager get wordTimings =>
      $$WordTimingsTableTableManager(_db.attachedDatabase, _db.wordTimings);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db.attachedDatabase, _db.ayahs);
}
