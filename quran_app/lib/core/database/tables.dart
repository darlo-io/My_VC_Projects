import 'package:drift/drift.dart';

/// Сурa (глава) Корана.
class Surahs extends Table {
  IntColumn get id => integer()();
  TextColumn get nameAr => text().named('name_ar')();
  TextColumn get nameEn => text().named('name_en')();
  TextColumn get nameTransliteration => text()();
  TextColumn get revelationType => text()();
  IntColumn get ayahCount => integer()();
  IntColumn get orderInMushaf => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Аят.
class Ayahs extends Table {
  IntColumn get id => integer()();
  IntColumn get surahId => integer().references(Surahs, #id)();
  IntColumn get ayahNumber => integer()();
  IntColumn get page => integer().nullable()();
  IntColumn get juz => integer().nullable()();
  IntColumn get hizb => integer().nullable()();
  TextColumn get textUthmani => text()();
  TextColumn get textNormalized => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Слово в аяте.
@DataClassName('Word')
class Words extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ayahId => integer().references(Ayahs, #id)();
  IntColumn get position => integer()();
  TextColumn get arabic => text()();
  TextColumn get normalized => text()();
  TextColumn get translation => text().nullable()();
  TextColumn get lemma => text().nullable()();
  TextColumn get root => text().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {ayahId, position},
      ];
}

/// Тайминги слова (для подсветки при прослушивании).
class WordTimings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id)();
  TextColumn get reciterId => text()();
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();
}

/// Чтецы.
class Reciters extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  TextColumn get style => text()();
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Переводчики.
class Translators extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get languageCode => text()();
  TextColumn get source => text()();
}

/// Переводы аятов.
@DataClassName('Translation')
class Translations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ayahId => integer().references(Ayahs, #id)();
  IntColumn get translatorId => integer().references(Translators, #id)();
  TextColumn get languageCode => text()();
  TextColumn get textValue => text().named('text')();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {ayahId, translatorId},
      ];
}

/// Источники тафсиров.
class TafsirSources extends Table {
  IntColumn get id => integer()();
  TextColumn get slug => text()();
  TextColumn get nameAr => text()();
  TextColumn get nameEn => text()();
  TextColumn get languageCode => text()();
}

/// Тафсиры.
class Tafsirs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ayahId => integer().references(Ayahs, #id)();
  IntColumn get tafsirSourceId => integer().references(TafsirSources, #id)();
  TextColumn get textValue => text().named('text')();
}

/// Закладки. UNIQUE(surah_id, ayah_id) предотвращает дубликаты.
@DataClassName('Bookmark')
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get surahId => integer().references(Surahs, #id)();
  IntColumn get ayahId => integer().references(Ayahs, #id)();
  IntColumn get ayahNumber => integer()();
  TextColumn get label => text().nullable()();
  IntColumn get color => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {surahId, ayahId},
      ];
}

/// Заметки.
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ayahId => integer().references(Ayahs, #id)();
  TextColumn get textValue => text().named('text')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Последняя позиция чтения (одна запись).
class LastPosition extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get surahId => integer()();
  IntColumn get ayahId => integer()();
  IntColumn get page => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// История чтения. UNIQUE(date, surah_id) даёт атомарный UPSERT.
class ReadingHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  IntColumn get surahId => integer()();
  IntColumn get ayahsRead => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {date, surahId},
      ];
}

/// Изучаемые слова (SM-2).
class LearningWords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id)();
  TextColumn get status => text()();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(0))();
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime()();
  DateTimeColumn get lastReviewAt => dateTime().nullable()();
}

/// Метаданные аудио-кеша.
@DataClassName('AudioCacheMetadatum')
class AudioCacheMetadata extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get reciterId => text()();
  IntColumn get surahId => integer()();
  TextColumn get filePath => text()();
  IntColumn get fileSizeBytes => integer()();
  DateTimeColumn get downloadedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {reciterId, surahId},
      ];
}

/// EAV-настройки (только для расширяемых данных, простые — в SharedPreferences).
class SettingsEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
