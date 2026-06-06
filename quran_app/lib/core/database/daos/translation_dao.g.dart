// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_dao.dart';

// ignore_for_file: type=lint
mixin _$TranslationDaoMixin on DatabaseAccessor<AppDatabase> {
  $SurahsTable get surahs => attachedDatabase.surahs;
  $AyahsTable get ayahs => attachedDatabase.ayahs;
  $TranslatorsTable get translators => attachedDatabase.translators;
  $TranslationsTable get translations => attachedDatabase.translations;
  TranslationDaoManager get managers => TranslationDaoManager(this);
}

class TranslationDaoManager {
  final _$TranslationDaoMixin _db;
  TranslationDaoManager(this._db);
  $$SurahsTableTableManager get surahs =>
      $$SurahsTableTableManager(_db.attachedDatabase, _db.surahs);
  $$AyahsTableTableManager get ayahs =>
      $$AyahsTableTableManager(_db.attachedDatabase, _db.ayahs);
  $$TranslatorsTableTableManager get translators =>
      $$TranslatorsTableTableManager(_db.attachedDatabase, _db.translators);
  $$TranslationsTableTableManager get translations =>
      $$TranslationsTableTableManager(_db.attachedDatabase, _db.translations);
}
