// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_dao.dart';

// ignore_for_file: type=lint
mixin _$LearningDaoMixin on DatabaseAccessor<AppDatabase> {
  $LearningWordsTable get learningWords => attachedDatabase.learningWords;
  $WordsTable get words => attachedDatabase.words;
  LearningDaoManager get managers => LearningDaoManager(this);
}

class LearningDaoManager {
  final _$LearningDaoMixin _db;
  LearningDaoManager(this._db);
  $$LearningWordsTableTableManager get learningWords =>
      $$LearningWordsTableTableManager(_db.attachedDatabase, _db.learningWords);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
}
