// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_dao.dart';

// ignore_for_file: type=lint
mixin _$LearningDaoMixin on DatabaseAccessor<AppDatabase> {
  $SurahsTable get surahs => attachedDatabase.surahs;
  $AyahsTable get ayahs => attachedDatabase.ayahs;
  $WordsTable get words => attachedDatabase.words;
  $LearningWordsTable get learningWords => attachedDatabase.learningWords;
  LearningDaoManager get managers => LearningDaoManager(this);
}

class LearningDaoManager {
  final _$LearningDaoMixin _db;
  LearningDaoManager(this._db);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db.attachedDatabase, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db.attachedDatabase, _db.ayahs);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$LearningWordsTableTableManager get learningWords =>
      $$LearningWordsTableTableManager(_db.attachedDatabase, _db.learningWords);
}
