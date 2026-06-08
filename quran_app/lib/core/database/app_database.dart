import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/audio_cache_dao.dart';
import 'daos/ayah_dao.dart';
import 'daos/bookmark_dao.dart';
import 'daos/position_dao.dart';
import 'daos/reciter_dao.dart';
import 'daos/surah_dao.dart';
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
  ],
  daos: [
    SurahDao,
    AyahDao,
    BookmarkDao,
    TranslationDao,
    PositionDao,
    ReciterDao,
    AudioCacheDao,
    WordsDao,
    WordTimingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createFts();
          await _createPerformanceIndexes();
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
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

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
  Future<void> _createPerformanceIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audio_cache_last_played '
      'ON audio_cache_metadata (last_played_at)',
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'quran_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
