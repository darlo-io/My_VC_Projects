// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_timings_dao.dart';

// ignore_for_file: type=lint
mixin _$WordTimingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SurahsTable get surahs => attachedDatabase.surahs;
  $AyahsTable get ayahs => attachedDatabase.ayahs;
  $WordsTable get words => attachedDatabase.words;
  $WordTimingsTable get wordTimings => attachedDatabase.wordTimings;
  WordTimingsDaoManager get managers => WordTimingsDaoManager(this);
}

class WordTimingsDaoManager {
  final _$WordTimingsDaoMixin _db;
  WordTimingsDaoManager(this._db);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db.attachedDatabase, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db.attachedDatabase, _db.ayahs);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$WordTimingsTableTableManager get wordTimings =>
      $$WordTimingsTableTableManager(_db.attachedDatabase, _db.wordTimings);
}
