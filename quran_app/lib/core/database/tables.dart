import 'package:drift/drift.dart';

/// Сурa (глава) Корана.
class Surahs extends Table {
  IntColumn get id => integer()();
  TextColumn get nameAr => text().named('name_ar')();
  TextColumn get nameEn => text().named('name_en')();
  TextColumn get nameTransliteration => text()();
  TextColumn get revelationType => text()();

  /// Русское название суры (например, «Аль-Фатиха»). Nullable —
  /// в seed-данных из `quran_full.json` его нет. Заполняется
  /// отдельной миграцией (см. v11→v12 в `app_database.dart`).
  TextColumn get nameRu => text().named('name_ru').nullable()();
  /// Подзаголовок/значение на русском (например, «Открывающая»).
  TextColumn get subtitleRu => text().named('subtitle_ru').nullable()();

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
///
/// `id` хранит синтетический `mp3quran:<mp3quran_id>` для всех ректоров,
/// приходящих из MP3Quran.net API через [Mp3QuranRepository.syncFromApi].
/// Старые app-id (`ar.alafasy`, …) больше не используются — UI
/// показывает русские/английские/арабские имена через fallback-логику.
///
/// Колонки `mp3quran_*` nullable: для ректоров, которых mp3quran.net
/// не отдаёт (legacy, крайне редко после первой полной синхронизации).
class Reciters extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text()();

  /// Локализованные имена чтеца. Из MP3Quran.net приходит одно
  /// `name` за вызов; `syncFromApi` трижды дёргает `/reciters?
  /// language=ar|ru|eng` и сливает результаты по `mp3quran_id`.
  ///
  /// При отображении в UI приоритет:
  ///   ru → en → ar (по коду локали устройства).
  ///
  /// `nameAr` остаётся NOT NULL — mp3quran-арабское имя доступно
  /// для всех ректоров (это «основное» имя в их системе). `nameRu`
  /// и `nameEn` nullable, потому что mp3quran может не поддерживать
  /// все локали для всех ректоров.
  TextColumn get nameAr => text()();
  TextColumn get nameRu => text().nullable()();
  TextColumn get nameEn => text().nullable()();
  TextColumn get style => text()();
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();

  /// Признак «избранного» — звёздочка в picker'е и быстрый доступ
  /// через секцию «Избранные». UI синхронизирует с
  /// [recitersRepositoryProvider.setFavorite].
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();

  // mp3quran.net lookup. Nullable: null = ректор не найден на
  // mp3quran.net или ещё не синхронизирован.
  IntColumn get mp3quranId => integer().nullable()();
  TextColumn get mp3quranServer =>
      text().nullable()(); // e.g. "https://server8.mp3quran.net/afs/"
  IntColumn get mp3quranMoshafId => integer().nullable()();
  IntColumn get mp3quranSurahTotal => integer().nullable()();
  TextColumn get mp3quranRewaya => text().nullable()(); // "Hafs A'n Assem - Murattal"
  IntColumn get mp3quranCachedAt =>
      integer().nullable()(); // DateTime timestamp; null = default seed

  /// `moshaf_type` от MP3Quran (`moshaf[0].moshaf_type`). Используется
  /// для определения «битрейта» в UI: типы 116/120/124 — Hafs, тип 51 —
  /// Mujawwad, и т.д. Конкретное значение kbps mp3quran.net в URL не
  /// отдаёт, но пути вида `/quran/audio/128/...` всегда 128 kbps, так что
  /// для отображения показываем «128 kbps» с уточнением реваята.
  IntColumn get mp3quranMoshafType => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Переводчики.
class Translators extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get languageCode => text()();

  /// Откуда пришёл перевод: `alquran.cloud`, `quran.com`, `local`.
  TextColumn get source => text()();

  /// **Round 8 (2026-07-23)**: id перевода в Quran.com API
  /// (`/resources/translations` → `id`). Используется для
  /// `fetchByAyah(translationId, ...)` / `fetchByChapter(...)`.
  /// Nullable — переводчики из alquran.cloud не имеют Quran.com id.
  IntColumn get quranComId => integer().nullable()();

  /// **Round 8**: русское display name для UI. Для Кулиева —
  /// «Кулиев», для Ministry of Awqaf — «Министерство вакфов
  /// Египта», для Abu Adel — «Абу Адель» (см. миграцию v15→v17).
  /// Nullable — для не-русских переводчиков поле пустое, UI
  /// fallback на `name`.
  TextColumn get nameRu => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
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

  /// Sprint 2.5.1: русское название тафсира (например, «Тафсир
  /// Ас-Саади»). Nullable: не все тафсиры Quran.com имеют
  /// русский перевод, и для legacy/source-local тафсиров поле тоже
  /// может быть null. UI fallback — `nameEn`. Заполняется
  /// через [TafsirsSyncService.forceSync] при `languageCode='ru'`
  /// (Quran.com API возвращает `translated_name.name` в нужном
  /// языке).
  TextColumn get nameRu => text().nullable()();

  TextColumn get languageCode => text()();

  /// Sprint 2.3: id тафсира в Quran.com API (для
  /// `/tafsirs/{quranComId}/by_ayah/{verseKey}`). Nullable — для
  /// legacy/source-local тафсиров (если такие будут). По этому полю
  /// UI-слой ищет tafsir source для fetchTafsirByAyah().
  IntColumn get quranComId => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
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

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {wordId},
      ];
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

/// Телеметрия аудио-прослушивания (master plan §4.4 + §11). Одна
/// запись на сессию: открывается в `AudioPlayerController.play(...)`,
/// закрывается на `stop`/смене суры/длинной паузе.
///
/// Retention: старше 90 дней подчищается [workmanager]-таском (см.
/// follow-up). Размер строки держим компактным: только то, что
/// потом пригодится Phase 2 (Statistics).
@DataClassName('PlaybackSession')
class PlaybackSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get reciterId => text()();
  IntColumn get surahId => integer().references(Surahs, #id)();
  IntColumn get ayahStart => integer()();

  /// Nullable: на момент `open()` ещё неизвестен — заполняется в
  /// [PlaybackSessionsDao.close]. Использовать `closeReason='pending'`
  /// как индикатор того, что сессия ещё не закрыта.
  IntColumn get ayahEnd => integer().nullable()();

  /// UTC, для кросс-часовых поясов (отображается через `intl`).
  DateTimeColumn get startedAt => dateTime()();

  /// Nullable — на момент `open()` равно `startedAt`, обновляется в
  /// `close()`. `closeReason='pending'` ⇔ `endedAt == startedAt`.
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// Длительность фактического воспроизведения (исключая паузы).
  /// `ended - started` даст wall-clock, `durationPlayedMs` —
  /// фактическое время в режиме play.
  IntColumn get durationPlayedMs => integer().withDefault(const Constant(0))();

  /// Причина закрытия: `pending` / `stop` / `surah_change` /
  /// `pause_timeout` / `pause` / `app_exit`. Полезно для агрегации
  /// в Phase 2 / Statistics.
  TextColumn get closeReason => text().withDefault(const Constant('pending'))();
}

/// Quran.com audio metadata — Sprint 1.5.
///
/// Отдельная таблица (а не колонки в [Reciters]) потому что:
//   1. Не нужно migration существующих строк (Sprint 1 стартует
//      с v12, эта таблица будет v13+ — drift создаст её автоматически).
//   2. Один ректор может иметь несколько Quran.com-вариантов
//      (per-verse vs per-surah, разные стили).
///   3. URL может быть вычислен без чтения БД — `kMp3quranToQuranCom`
///      уже предоставляет static mapping. Эта таблица для per-reciter
///      overrides (reciters без static mapping — напр. custom импорты).
class QuranComReciters extends Table {
  /// `reciterId` из [Reciters.id] (формат `mp3quran:NNN` или
  /// `quran_com:NNN` — мы поддерживаем оба, чтобы UI мог использовать
  /// любой source).
  TextColumn get reciterId => text()();

  /// Quran.com recitation id (используется в /recitations/{id}/by_chapter/N).
  IntColumn get quranComId => integer()();

  /// Sub-folder на CDN вида "Alafasy", "Husary", и т.д.
  /// (см. [QuranComRecitationDto.path]).
  TextColumn get path => text()();

  /// Стиль чтения (Murattal, Mujawwad, Muallim, …). Nullable —
  /// для рива'ат без явного стиля.
  TextColumn get style => text().nullable()();

  /// Reciter name на языке UI (запрошенном при sync).
  TextColumn get nameLocalized => text()();

  /// Когда запись была последний раз синхронизирована с API.
  /// Используется для TTL-cache: `syncedAt < now - 7d` → нужно
  /// пересинхронизировать.
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {reciterId};
}
