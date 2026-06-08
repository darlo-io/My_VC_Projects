// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_dao.dart';

// ignore_for_file: type=lint
mixin _$TranslationDaoMixin on DatabaseAccessor<AppDatabase> {
  $TranslationsTable get translations => attachedDatabase.translations;
  $TranslatorsTable get translators => attachedDatabase.translators;
  TranslationDaoManager get managers => TranslationDaoManager(this);
}

class TranslationDaoManager {
  final _$TranslationDaoMixin _db;
  TranslationDaoManager(this._db);
  $$TranslationsTableTableManager get translations =>
      $$TranslationsTableTableManager(_db.attachedDatabase, _db.translations);
  $$TranslatorsTableTableManager get translators =>
      $$TranslatorsTableTableManager(_db.attachedDatabase, _db.translators);
}
