// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_dao.dart';

// ignore_for_file: type=lint
mixin _$TranslationDaoMixin on DatabaseAccessor<AppDatabase> {
  $TranslationsTable get translations => attachedDatabase.translations;
  $TranslatorsTable get translators => attachedDatabase.translators;
  $AyahsTable get ayahs => attachedDatabase.ayahs;
  $SurahsTable get surahs => attachedDatabase.surahs;
  TranslationDaoManager get managers => TranslationDaoManager(this);
}

class TranslationDaoManager {
  final _$TranslationDaoMixin _db;
  TranslationDaoManager(this._db);
  $$TranslationsTableTableManager get translations =>
      $$TranslationsTableTableManager(_db.attachedDatabase, _db.translations);
  $$TranslatorsTableTableManager get translators =>
      $$TranslatorsTableTableManager(_db.attachedDatabase, _db.translators);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db.attachedDatabase, _db.ayahs);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db.attachedDatabase, _db.surahs);
}
