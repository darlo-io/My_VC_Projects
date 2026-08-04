import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/audio_cache_dao.dart';
import 'daos/search_dao.dart';
import 'daos/ayah_dao.dart';
import 'daos/bookmark_dao.dart';
import 'daos/learning_dao.dart';
import 'daos/notes_dao.dart';
import 'surah_ru_names.dart';
import 'daos/playback_sessions_dao.dart';
import 'daos/position_dao.dart';
import 'daos/quran_com_reciter_dao.dart';
import 'daos/reciter_dao.dart';
import 'daos/surah_dao.dart';
import 'daos/tafsir_dao.dart';
import 'daos/translation_dao.dart';
import 'daos/word_timings_dao.dart';
import 'daos/words_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Surahs,
    Ayahs,
    Words,
    WordTimings,
    Reciters,
    Translators,
    Translations,
    TafsirSources,
    Tafsirs,
    Bookmarks,
    Notes,
    LastPosition,
    ReadingHistory,
    LearningWords,
    AudioCacheMetadata,
    SettingsEntries,
    PlaybackSessions,
    QuranComReciters,
  ],
  daos: [
    SurahDao,
    AyahDao,
    BookmarkDao,
    TranslationDao,
    PositionDao,
    ReciterDao,
    QuranComReciterDao,
    AudioCacheDao,
    SearchDao,
    WordsDao,
    WordTimingsDao,
    LearningDao,
    NotesDao,
    PlaybackSessionsDao,
    TafsirDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 19;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createFts();
      await _createPerformanceIndexes();
      // Backfill the `Ayahs.juz` column from the
      // [kJuzStarts] table. Idempotent (the UPDATE is
      // gated on `juz IS NULL`), so re-running the
      // migration is a no-op.
      await ayahDao.backfillJuzColumn();
      // Backfill the `Ayahs.page` and `Ayahs.hizb` columns
      // from [kQuranLayout]. The [kQuranLayout] table is
      // an approximation (see its file header for the
      // caveats); the columns are still better than NULL
      // for the "what page am I on?" UI, and a real
      // dataset can replace the table in one shot without
      // touching this migration.
      await ayahDao.backfillPageAndHizbColumn();
    },
    onUpgrade: (m, from, to) async {
      // MIGRATION CONTRACT — read before bumping schemaVersion.
      //
      
      // Pre-v5 installs (dev-era, never shipped): we drop and re-create.
      //   Acceptable because the app has not been released and no users
      //   have data worth preserving.
      //
      // v5 and above: ADDITIVE MIGRATIONS ONLY. Never call
      //   `m.deleteTable` for v5+ upgrades. Use `m.addColumn`,
      //   `m.alterTable`, `m.createTable`, or `customStatement` for
      //   indexes/tables you genuinely need to add. User data (bookmarks,
      //   notes, reading_history, last_position) MUST survive upgrades.
      //
      // Template for v5 -> v6 and onward (append a new if-branch):
      //   if (from < 6) {
      //     await m.addColumn(notes, notes.priority);
      //     // ...other additive changes
      //   }
      if (from < 5) {
        await _resetSchema(m);
      }

      if (from < 6) {
        // v5 -> v6 (and pre-v5 paths via the reset above): add the
        // LRU-eviction index. `oldestFirst()` in AudioCacheDao orders
        // by last_played_at; without this index it's a full scan.
        // Safe to re-run on already-migrated DBs thanks to IF NOT EXISTS.
        await m.database.customStatement(
          'CREATE INDEX IF NOT EXISTS idx_audio_cache_last_played '
          'ON audio_cache_metadata (last_played_at)',
        );
      }

      if (from >= 5 && from < 7) {
        // v5 -> v7: backfill the `Ayahs.juz` column from
        // [kJuzStarts]. Pre-v5 was reset above and re-runs
        // through `onCreate` which also backfills, so we
        // only need the explicit call for the v5 -> v7 path
        // and the v6 -> v7 path. Idempotent.
        await ayahDao.backfillJuzColumn();
        // Same window: backfill page/hizb from
        // [kQuranLayout]. Also idempotent.
        await ayahDao.backfillPageAndHizbColumn();
      }

      // Idempotently (re)create the FTS5 shadow tables and
      // their sync triggers for any DB upgraded from an older
      // build that may have been created before
      // `tafsirs_fts` existed. CREATE ... IF NOT EXISTS
      // means this is a no-op on already-migrated installs.
      await _createFts();

      if (from < 8) {
        // v7 -> v8: enforce one-to-one between LearningWords
        // and Words. Without the UNIQUE, two parallel
        // `addWord(sameId)` calls could both pass a
        // `getSingleOrNull == null` check and then crash on
        // the auto-incremented PK insert (well, the PK
        // wouldn't actually collide — but the row would be
        // duplicated, and the next `recordReview` would
        // throw `TooManyResultsException` on its
        // `getSingle`). De-dup existing rows first so the
        // UNIQUE INDEX can be created. Keep the row with
        // the highest `id` (the most recent review state)
        // and drop the rest.
        await customStatement('''
              DELETE FROM learning_words
              WHERE id NOT IN (
                SELECT MAX(id) FROM learning_words GROUP BY word_id
              )
            ''');
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_learning_words_word_id '
          'ON learning_words (word_id)',
        );
      }

      if (from < 9) {
        // v8 -> v9: add audio-playback telemetry (master plan §4.4).
        // Additive migration: new table `playback_sessions` + index
        // on `(reciter_id, started_at)` for fast per-reciter queries
        // from Phase 2 Statistics. No backfill needed — table starts
        // empty and writes happen at runtime from the
        // `AudioPlayerController`.
        await m.createTable(playbackSessions);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_playback_sessions_reciter_started '
          'ON playback_sessions (reciter_id, started_at)',
        );
      }

      if (from < 10) {
        // v9 -> v10: MP3Quran.net integration (см. AGENTS.md
        // «Audio playback»). Additive — добавляет nullable-колонки
        // к `reciters` для хранения mp3quran-метаданных (server URL,
        // moshaf id, rewaya, кэш timestamp). Не трогает существующие
        // ряды: дефолтные 8 ректоров заполняются при следующем
        // [Mp3QuranRepository.syncDefaultReciters]. Для новых
        // ректоров из API — через [syncFromApi].
        await m.addColumn(reciters, reciters.mp3quranId);
        await m.addColumn(reciters, reciters.mp3quranServer);
        await m.addColumn(reciters, reciters.mp3quranMoshafId);
        await m.addColumn(reciters, reciters.mp3quranSurahTotal);
        await m.addColumn(reciters, reciters.mp3quranRewaya);
        await m.addColumn(reciters, reciters.mp3quranCachedAt);
      }

      if (from < 11) {
        // v10 -> v11: редизайн listen-экрана (см. AGENTS.md
        // «Audio playback»). Additive — добавляет к `reciters`:
        //   * `nameRu` (nullable) — русское имя чтеца;
        //   * `nameEn` (nullable) — английское имя (NB: name_en мог
        //     быть создан в схеме v9; идемпотентность обязательна);
        //   * `is_favorite` (default 0) — отметка избранного;
        //   * `mp3quran_moshaf_type` (nullable) — тип мусхафа.
        //
        // SQLite НЕ поддерживает `ADD COLUMN IF NOT EXISTS` (это
        // Postgres-фича). Используем `PRAGMA table_info` для проверки
        // наличия колонки перед ALTER. Идемпотентно — повторный запуск
        // с уже-применённой миграцией просто скипает существующие
        // колонки.
        Future<void> addColumnIfMissing(String col, String definition) async {
          final rows = await m.database.customSelect(
            "SELECT name FROM pragma_table_info('reciters')",
          ).get();
          final exists = rows.any((r) => r.read<String>('name') == col);
          if (!exists) {
            await m.database
                .customStatement('ALTER TABLE reciters ADD COLUMN $col $definition');
          }
        }

        await addColumnIfMissing('name_ru', 'TEXT');
        await addColumnIfMissing('name_en', 'TEXT');
        await addColumnIfMissing(
            'is_favorite', 'INTEGER NOT NULL DEFAULT 0');
        await addColumnIfMissing('mp3quran_moshaf_type', 'INTEGER');
      }

      if (from < 12) {
        // v11 -> v12: редизайн listen-экрана, фаза 2 (см. AGENTS.md
        // «Audio playback»). Additive — добавляет к `surahs`:
        //   * `name_ru` (nullable) — русское название суры
        //     («Аль-Фатиха», «Аль-Бакара» и т.д.);
        //   * `subtitle_ru` (nullable) — русский подзаголовок
        //     («Открывающая», «Корова» и т.д.).
        //
        // Старые ряды получают `name_ru = NULL` сразу после
        // миграции. Ниже — backfill, который заполняет их из
        // [kSurahRuNames] / [kSurahRuSubtitles] (см.
        // `lib/core/database/surah_ru_names.dart`). Идемпотентно —
        // повторный запуск с уже-заполненными рядами обновляет
        // значения только если они NULL.
        await m.addColumn(surahs, surahs.nameRu);
        await m.addColumn(surahs, surahs.subtitleRu);
        await _backfillRussianSurahNames(m.database);
      }

      if (from < 14) {
        // v13 -> v14: Quran.com Tafsir integration (Sprint 2).
        // Additive — добавляет nullable `quran_com_id` к
        // `tafsir_sources` для маппинга local auto-increment id →
        // Quran.com tafsir id (например, 14 = Tafsir Ibn Kathir
        // Arabic, 170 = Al-Sa'di Russian).
        // Nullable: legacy/source-local тафсиры (если такие
        // будут) могут остаться без Quran.com id — fallback в UI.
        // Без `IF NOT EXISTS` (Postgres-фича) — проверяем через
        // `PRAGMA table_info` (см. _backfillRussianSurahNames для
        // аналогичного паттерна с v11→v12).
        final tafsirSourceCols = await customSelect(
          "SELECT name FROM pragma_table_info('tafsir_sources')",
          readsFrom: {tafsirSources},
        ).get();
        final hasQuranComId = tafsirSourceCols
            .any((r) => r.read<String>('name') == 'quran_com_id');
        if (!hasQuranComId) {
          await m.addColumn(tafsirSources, tafsirSources.quranComId);
        }
      }

      if (from < 16) {
        // v15 -> v16: localized tafsir source name (Sprint 2.5.1).
        // Добавляет nullable `name_ru` к `tafsir_sources`.
        //
        // Зачем: до этого миграции UI выводил `s.nameEn` напрямую
        // (см. `tafsir_panel.dart:_buildSourceList`), даже когда
        // текущая локаль приложения — русская, и в `nameEn` лежал
        // русский перевод из-за бага в `TafsirsSyncService` (он
        // пишет `translated_name` от Quran.com в `name_en` независимо
        // от языка запроса). Имена авторов отображались либо на
        // английском (если кеш был старый), либо на странной смеси.
        //
        // Sprint 2.5.1 fix:
        //   - `name_ru` колонка для русского перевода;
        //   - `TafsirsSyncService.forceSync(languageCode: 'ru')` теперь
        //     пишет `translatedName` в `nameRu` (а не `nameEn`);
        //   - `tafsir_panel._buildSourceList` показывает `nameRu` для
        //     локали ru, иначе `nameEn`;
        //   - backfill существующих рядов: текущий `nameEn` мог
        //     быть русским переводом (старый sync на русской локали).
        //     Консервативно **копируем** `nameEn` → `nameRu` для
        //     рядов с `language_code='ru'`, чтобы UI не показывал
        //     английский fallback там, где раньше был русский. Для
        //     других локалей (ar, en) name_ru остаётся NULL — там
        //     `name_en` действительно английский, что корректно.
        //
        // Идемпотентно (см. v11→v12 паттерн с PRAGMA table_info).
        final tafsirSourceCols2 = await customSelect(
          "SELECT name FROM pragma_table_info('tafsir_sources')",
          readsFrom: {tafsirSources},
        ).get();
        final hasNameRu = tafsirSourceCols2
            .any((r) => r.read<String>('name') == 'name_ru');
        if (!hasNameRu) {
          await m.addColumn(tafsirSources, tafsirSources.nameRu);
          // Backfill: для рядов с language_code='ru' копируем
          // nameEn в nameRu. Если новый sync перезапишет — это
          // ожидаемо (correct translation for current locale).
          await customStatement(
            "UPDATE tafsir_sources SET name_ru = name_en "
            "WHERE language_code = 'ru' AND name_ru IS NULL",
          );
        }
      }

      if (from < 18) {
        // v17 -> v18 (Round 8): добавляем `quran_com_id` и `name_ru`
        // к `translators`. Round 8 — переход с alquran.cloud на
        // Quran.com API: даём пользователю выбор перевода (Кулиев,
        // Ministry of Awqaf Egypt, Abu Adel).
        //
        // Идемпотентно — проверяем `pragma_table_info` перед
        // добавлением колонки (паттерн v11→v12, v15→v16).
        // (Раньше этот блок был под `if (from < 17)`, но v17 уже
        // занят tafsir_sources миграцией, поэтому я перенёс на v18.)
        final translatorCols = await customSelect(
          "SELECT name FROM pragma_table_info('translators')",
          readsFrom: {translators},
        ).get();
        final hasQuranComId = translatorCols
            .any((r) => r.read<String>('name') == 'quran_com_id');
        if (!hasQuranComId) {
          await m.addColumn(
            translators,
            translators.quranComId as GeneratedColumn<Object>,
          );
        }
        final hasNameRu = translatorCols
            .any((r) => r.read<String>('name') == 'name_ru');
        if (!hasNameRu) {
          await m.addColumn(
            translators,
            translators.nameRu as GeneratedColumn<Object>,
          );
        }
      }

      // (dead-code удалён — Round 8 перезаписывает старый v17-блок
      // который ошибочно остался от моей правки в Round 7.)

      if (from < 19) {
        // v18 -> v19: re-backfill `surahs.name_ru/subtitle_ru` из
        // обновлённых `kSurahRuNames/kSurahRuSubtitles` (2026-08-02:
        // 17 имён + 28 подзаголовков). v11→v12 backfill использовал
        // `IS NULL` guard и не обновлял уже-заполненные ряды, поэтому
        // исправления у существующих пользователей не подхватывались.
        //
        // Без `IS NULL` — безусловный UPDATE всех 114 рядов. Безопасно:
        // `name_ru/subtitle_ru` read-only из файла `kSurahRuNames`,
        // пользовательская кастомизация не предусмотрена.
        await _backfillRussianSurahNamesUnconditional(m.database);
      }
    },
  );

  /// Backfill `name_ru` / `subtitle_ru` для сур — идемпотентно
  /// (UPDATE только для NULL). Вызывается из миграции v11→v12.
  ///
  /// Использует [customUpdate] с явным указанием [surahs] в `updates:` —
  /// это решает проблему с порядком параметров: `db.customStatement` без
  /// `updates:` путает `?` позиции, а `customUpdate` привязывает их
  /// к колонкам таблицы, так что первый `?` идёт в первую колонку
  /// (`name_ru` / `subtitle_ru`), а второй — в `id`.
  Future<void> _backfillRussianSurahNames(GeneratedDatabase db) async {
    for (var i = 1; i <= 114; i++) {
      final name = kSurahRuNames[i];
      final sub = kSurahRuSubtitles[i];
      if (name != null) {
        await db.customUpdate(
          'UPDATE surahs SET name_ru = ? WHERE id = ? AND name_ru IS NULL',
          updates: {surahs},
          variables: [
            Variable.withString(name),
            Variable.withInt(i),
          ],
        );
      }
      if (sub != null) {
        await db.customUpdate(
          'UPDATE surahs SET subtitle_ru = ? WHERE id = ? AND subtitle_ru IS NULL',
          updates: {surahs},
          variables: [
            Variable.withString(sub),
            Variable.withInt(i),
          ],
        );
      }
    }
  }

  /// Безусловный re-backfill `name_ru` / `subtitle_ru` для сур —
  /// перезаписывает все 114 рядов. Вызывается из миграции v18→v19
  /// для подхвата исправленных имён/подзаголовков у существующих
  /// установок (v11→v12 backfill с `IS NULL` guard не обновляет
  /// уже-заполненные ряды).
  ///
  /// Безопасно: `name_ru/subtitle_ru` read-only из файла
  /// `kSurahRuNames/kSurahRuSubtitles`, пользовательская кастомизация
  /// не предусмотрена в текущей модели данных.
  Future<void> _backfillRussianSurahNamesUnconditional(
    GeneratedDatabase db,
  ) async {
    for (var i = 1; i <= 114; i++) {
      final name = kSurahRuNames[i];
      final sub = kSurahRuSubtitles[i];
      if (name != null) {
        await db.customUpdate(
          'UPDATE surahs SET name_ru = ? WHERE id = ?',
          updates: {surahs},
          variables: [
            Variable.withString(name),
            Variable.withInt(i),
          ],
        );
      }
      if (sub != null) {
        await db.customUpdate(
          'UPDATE surahs SET subtitle_ru = ? WHERE id = ?',
          updates: {surahs},
          variables: [
            Variable.withString(sub),
            Variable.withInt(i),
          ],
        );
      }
    }
  }

  // (Удалено в Round 8 — `_backfillTafsirRuNames` не использовался.
  // Аналогичный backfill, если потребуется в следующих раундах,
  // можно добавить рядом с [ContentBootstrapper].)

  /// Destructive schema reset. Used ONLY for pre-v5 installs.
  /// Must not be reachable from a v5+ upgrade path.
  Future<void> _resetSchema(Migrator m) async {
    await m.deleteTable('settings_entries');
    await m.deleteTable('audio_cache_metadata');
    await m.deleteTable('learning_words');
    await m.deleteTable('reading_history');
    await m.deleteTable('last_position');
    await m.deleteTable('notes');
    await m.deleteTable('bookmarks');
    await m.deleteTable('tafsirs');
    await m.deleteTable('tafsir_sources');
    await m.deleteTable('translations');
    await m.deleteTable('translators');
    await m.deleteTable('reciters');
    await m.deleteTable('word_timings');
    await m.deleteTable('words');
    await m.deleteTable('ayahs');
    await m.deleteTable('surahs');
    await m.createAll();
    await _createFts();
    await _createPerformanceIndexes();
  }

  /// Performance indexes created on fresh installs and on the reset path.
  /// Kept separate from FTS5 setup so future index additions stay grouped.
  ///
  /// Round 9.6 (code review #M1): добавлен `idx_words_ayah_id`.
  /// Запрос `getWordsForAyah(ayahId)` (`WHERE ayah_id = ? ORDER BY position`)
  /// без индекса на `ayah_id` делает full table scan на таблице
  /// из ~187k строк (6236 аятов × ~30 слов). С индексом —
  /// O(log N) lookup + покрывающий sort по `position`.
  Future<void> _createPerformanceIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audio_cache_last_played '
      'ON audio_cache_metadata (last_played_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_words_ayah_id '
      'ON words (ayah_id)',
    );
  }

  Future<void> _createFts() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS ayahs_fts USING fts5(
        text_uthmani,
        text_normalized,
        content='ayahs',
        content_rowid='id',
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS translations_fts USING fts5(
        text,
        content='translations',
        content_rowid='id',
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS tafsirs_fts USING fts5(
        text,
        content='tafsirs',
        content_rowid='id',
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS words_fts USING fts5(
        arabic,
        normalized,
        translation,
        lemma,
        root,
        content='words',
        content_rowid='id',
        tokenize='unicode61 remove_diacritics 2'
      )
    ''');

    // Триггеры для синхронизации FTS (полный набор: insert/delete/update)
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS ayahs_ai AFTER INSERT ON ayahs BEGIN
        INSERT INTO ayahs_fts(rowid, text_uthmani, text_normalized)
        VALUES (new.id, new.text_uthmani, new.text_normalized);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS ayahs_ad AFTER DELETE ON ayahs BEGIN
        INSERT INTO ayahs_fts(ayahs_fts, rowid, text_uthmani, text_normalized)
        VALUES ('delete', old.id, old.text_uthmani, old.text_normalized);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS ayahs_au AFTER UPDATE ON ayahs BEGIN
        INSERT INTO ayahs_fts(ayahs_fts, rowid, text_uthmani, text_normalized)
        VALUES ('delete', old.id, old.text_uthmani, old.text_normalized);
        INSERT INTO ayahs_fts(rowid, text_uthmani, text_normalized)
        VALUES (new.id, new.text_uthmani, new.text_normalized);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS translations_ai AFTER INSERT ON translations BEGIN
        INSERT INTO translations_fts(rowid, text)
        VALUES (new.id, new.text);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS translations_ad AFTER DELETE ON translations BEGIN
        INSERT INTO translations_fts(translations_fts, rowid, text)
        VALUES ('delete', old.id, old.text);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS translations_au AFTER UPDATE ON translations BEGIN
        INSERT INTO translations_fts(translations_fts, rowid, text)
        VALUES ('delete', old.id, old.text);
        INSERT INTO translations_fts(rowid, text)
        VALUES (new.id, new.text);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS tafsirs_ai AFTER INSERT ON tafsirs BEGIN
        INSERT INTO tafsirs_fts(rowid, text)
        VALUES (new.id, new.text);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS tafsirs_ad AFTER DELETE ON tafsirs BEGIN
        INSERT INTO tafsirs_fts(tafsirs_fts, rowid, text)
        VALUES ('delete', old.id, old.text);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS tafsirs_au AFTER UPDATE ON tafsirs BEGIN
        INSERT INTO tafsirs_fts(tafsirs_fts, rowid, text)
        VALUES ('delete', old.id, old.text);
        INSERT INTO tafsirs_fts(rowid, text)
        VALUES (new.id, new.text);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS words_ai AFTER INSERT ON words BEGIN
        INSERT INTO words_fts(rowid, arabic, normalized, translation, lemma, root)
        VALUES (
          new.id, new.arabic, new.normalized, IFNULL(new.translation,''),
          IFNULL(new.lemma,''), IFNULL(new.root,'')
        );
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS words_ad AFTER DELETE ON words BEGIN
        INSERT INTO words_fts(words_fts, rowid, arabic, normalized, translation, lemma, root)
        VALUES (
          'delete', old.id, old.arabic, old.normalized, IFNULL(old.translation,''),
          IFNULL(old.lemma,''), IFNULL(old.root,'')
        );
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS words_au AFTER UPDATE ON words BEGIN
        INSERT INTO words_fts(words_fts, rowid, arabic, normalized, translation, lemma, root)
        VALUES (
          'delete', old.id, old.arabic, old.normalized, IFNULL(old.translation,''),
          IFNULL(old.lemma,''), IFNULL(old.root,'')
        );
        INSERT INTO words_fts(rowid, arabic, normalized, translation, lemma, root)
        VALUES (
          new.id, new.arabic, new.normalized, IFNULL(new.translation,''),
          IFNULL(new.lemma,''), IFNULL(new.root,'')
        );
      END
    ''');
  }

  /// Удалить **только пользовательские данные**:
  /// bookmarks, notes, last_position, reading_history, learning_words.
  /// Контент (surahs, ayahs, words, translations, tafsirs) и
  /// метаданные кеша аудио сохраняются — после wipe приложение
  /// остаётся читабельным, а закладки/заметки/прогресс начинаются
  /// с чистого листа. Триггеры FTS5 также остаются — они часть
  /// схемы, а не данных.
  ///
  /// Внутри одной транзакции, чтобы сброс был атомарен: если
  /// одна таблица бросит — ничего не удалится, и пользователь
  /// увидит ошибку, а не половину очищенного состояния.
  Future<void> wipeUserData() async {
    await transaction(() async {
      await customStatement('DELETE FROM bookmarks');
      await customStatement('DELETE FROM notes');
      await customStatement('DELETE FROM last_position');
      await customStatement('DELETE FROM reading_history');
      await customStatement('DELETE FROM learning_words');
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'quran_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
