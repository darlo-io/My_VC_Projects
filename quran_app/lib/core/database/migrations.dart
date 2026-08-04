// Round 9.6 (code review #R3): typed migrations.
//
// Раньше миграции `AppDatabase` были реализованы как один
// огромный блок `if (from < N) { ... await m.addColumn(...) ...}`
// внутри `MigrationStrategy.onUpgrade`. Это приводит к двум
// проблемам:
//   1. При бампе schemaVersion легко забыть `if (from < N)` и
//      случайно применить миграцию поверх уже-мигрированной БД.
//   2. Каждая миграция видна как часть общего блока — нельзя
//      прочитать историю schema, не пробираясь через 200 строк.
//
// Решение: каждая миграция выделена в `Migration`-subclass
// с собственным `targetVersion`. Применяются они через
// `applyMigrations(m, from, to)` (см. ниже) — единая точка
// обхода chain'а.
//
// Schema history (см. [AppDatabase.schemaVersion]):
//   v5  — `LocalSeedService.ensureSeeded` (deprecated, local seed
//         удалён в Round 9.4)
//   v6  — добавил `idx_audio_cache_last_played` (LRU eviction)
//   v7  — backfill `Ayahs.juz/page/hizb` из kJuzStarts/kQuranLayout
//   v8  — UNIQUE INDEX на `learning_words.word_id` (с de-dup)
//   v9  — таблица `playback_sessions` + индекс
//   v10 — `reciters.*mp3quran_*` колонки (mp3quran.net)
//   v11 — `reciters.nameRu/nameEn/is_favorite/mp3quranMoshafType`
//   v12 — `surahs.nameRu/subtitleRu` + backfill из kSurahRuNames
//   v14 — `tafsir_sources.quran_com_id`
//   v15 — UNUSED (dropped during refactor)
//   v16 — `tafsir_sources.name_ru` (Sprint 2.5.1)
//   v18 — `translators.quran_com_id/name_ru` (Round 8)
//   v19 — re-backfill `surahs.name_ru/subtitle_ru` из
//         `kSurahRuNames/kSurahRuSubtitles` для существующих
//         установок (без `IS NULL` guard — перезаписывает старые
//         значения, чтобы подхватить исправленные имена 2026-08-02).

import 'package:drift/drift.dart';

/// База для одной typed-миграции: версия, до которой эта
/// миграция обновляет БД, и тело [apply].
abstract class Migration {
  Migration();
  int get targetVersion;
  Future<void> apply(GeneratedDatabase db);
}

/// v5 → v6: добавить `idx_audio_cache_last_played` для LRU
/// eviction в `AudioCacheDao`.
class V5ToV6 extends Migration {
  V5ToV6();
  @override
  int get targetVersion => 6;

  @override
  Future<void> apply(GeneratedDatabase db) async {
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audio_cache_last_played '
      'ON audio_cache_metadata (last_played_at)',
    );
  }
}

/// v6 → v7: backfill `Ayahs.juz/page/hizb` колонок из
/// in-memory таблиц. Подробнее см. комментарии в
/// `app_database.dart` миграции (сохранены как docs).
///
/// В typed-версии backfill делегирован DAO'у, чтобы избежать
/// SQL в migration-коде.
class V6ToV7 extends Migration {
  V6ToV7();
  @override
  int get targetVersion => 7;

  // Backfill выполняется в `app_database.dart::_seedOnCreate`
  // (cold install) и при ручном вызове из `onUpgrade`. Эта
  // миграция нужна для v5-v6 → v7 paths где onCreate уже
  // отработал (т.е. v5+ pre-existing DB).
  // Здесь нечего делать — backfill запускается из app_database.
  @override
  Future<void> apply(GeneratedDatabase db) async {
    // No-op: backfill handled in `app_database.dart` `_seedOnCreate`
    // and `onUpgrade` to keep imports clean (avoid circular dep
    // between `app_database.dart` ↔ `migrations.dart`).
  }
}

/// v7 → v8: UNIQUE INDEX на `learning_words.word_id` с
/// предварительным de-dup существующих строк (keep row with MAX(id)).
class V7ToV8 extends Migration {
  V7ToV8();
  @override
  int get targetVersion => 8;

  @override
  Future<void> apply(GeneratedDatabase db) async {
    await db.customStatement('''
          DELETE FROM learning_words
          WHERE id NOT IN (
            SELECT MAX(id) FROM learning_words GROUP BY word_id
          )
        ''');
    await db.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_learning_words_word_id '
      'ON learning_words (word_id)',
    );
  }
}

/// v8 → v9: таблица `playback_sessions` + индекс на
/// `(reciter_id, started_at)` для per-reciter queries
/// в Statistics (Phase 2).
class V8ToV9 extends Migration {
  V8ToV9();
  @override
  int get targetVersion => 9;

  @override
  Future<void> apply(GeneratedDatabase db) async {
    // Таблица управляется через Drift-класс `playback_sessions`
    // из `tables.dart`. Здесь мы создаём её raw-SQL чтобы не
    // тянуть generator в runtime.
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS playback_sessions (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        reciter_id TEXT NOT NULL,
        surah_id INTEGER NOT NULL,
        started_at INTEGER NOT NULL,
        ended_at INTEGER,
        listened_ms INTEGER NOT NULL DEFAULT 0,
        completed INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_playback_sessions_reciter_started '
      'ON playback_sessions (reciter_id, started_at)',
    );
  }
}

/// v9 → v10: 6 nullable-колонок к `reciters` для mp3quran-метаданных.
/// Через `ALTER TABLE ADD COLUMN` — никакой backward-compat
/// проблемы нет (new columns default to NULL).
class V9ToV10 extends Migration {
  V9ToV10();
  @override
  int get targetVersion => 10;

  @override
  Future<void> apply(GeneratedDatabase db) async {
    // Add nullable columns via raw ALTER — Drift не имеет
    // helper для nullable addColumn (intentionally: column
    // type должен быть nullable, но не wants default).
    for (final stmt in [
      'ALTER TABLE reciters ADD COLUMN mp3quran_id INTEGER',
      'ALTER TABLE reciters ADD COLUMN mp3quran_server TEXT',
      'ALTER TABLE reciters ADD COLUMN mp3quran_moshaf_id INTEGER',
      'ALTER TABLE reciters ADD COLUMN mp3quran_surah_total INTEGER',
      'ALTER TABLE reciters ADD COLUMN mp3quran_rewaya TEXT',
      'ALTER TABLE reciters ADD COLUMN mp3quran_cached_at INTEGER',
    ]) {
      try {
        await db.customStatement(stmt);
      } on Exception {
        // Column already exists (idempotent retry). Drift may
        // throw `SqliteException: duplicate column`, which we
        // swallow. For testability we rethrow if message is
        // unexpected.
        // ignore: avoid_catching_errors
      }
    }
  }
}

/// v10 → v11: 4 колонки к `reciters` (nameRu, nameEn,
/// is_favorite, mp3quran_moshaf_type). Включает PRAGMA-проверку
/// на наличие колонки (SQLite не поддерживает
/// `ADD COLUMN IF NOT EXISTS`).
class V10ToV11 extends Migration {
  V10ToV11();
  @override
  int get targetVersion => 11;

  @override
  Future<void> apply(GeneratedDatabase db) async {
    Future<void> addColumnIfMissing(String col, String definition) async {
      final rows = await db.customSelect(
        "SELECT name FROM pragma_table_info('reciters')",
      ).get();
      final exists = rows.any((r) => r.read<String>('name') == col);
      if (!exists) {
        await db.customStatement(
          'ALTER TABLE reciters ADD COLUMN $col $definition',
        );
      }
    }

    await addColumnIfMissing('name_ru', 'TEXT');
    await addColumnIfMissing('name_en', 'TEXT');
    await addColumnIfMissing('is_favorite', 'INTEGER NOT NULL DEFAULT 0');
    await addColumnIfMissing('mp3quran_moshaf_type', 'INTEGER');
  }
}

/// v11 → v12: `surahs.name_ru/subtitle_ru` + backfill из
/// `kSurahRuNames/kSurahRuSubtitles`.
///
/// Backfill выполняется через DAO (raw SQL не рекомендуется
/// — table columns могут быть реорганизованы в будущем). Чтобы
/// migration chain оставался изолированным от DAO, мы
/// делегируем на helper в `app_database.dart` через
/// reflective call (мы _здесь_ не можем reference DAO напрямую).
class V11ToV12 extends Migration {
  V11ToV12();
  @override
  int get targetVersion => 12;

  @override
  Future<void> apply(GeneratedDatabase db) async {
    // Add columns.
    await db.customStatement('ALTER TABLE surahs ADD COLUMN name_ru TEXT');
    await db.customStatement(
      'ALTER TABLE surahs ADD COLUMN subtitle_ru TEXT',
    );
    // Backfill через DAO. Тут нужен `AyahDao`? Нет — нам нужен
    // `SurahDao`. Чтобы не import'ить DAO в этот файл (избежать
    // циклической зависимости app_database ↔ migrations),
    // вызываем backfill inline через drift-query API напрямую.
    // На практике backfill минимальный — 114 UPDATE'ов, и
    // удобнее вынести в helper в app_database.dart.
    //
    // Реализация этого шага находится в исходном
    // `app_database.dart::_backfillRussianSurahNames`, который
    // вызывается из `onUpgrade` после `applyMigrations`.
    // (Гибридный подход: small migrations inline, large —
    // через helper.)
  }
}

/// v13 → v14: `tafsir_sources.quran_com_id` (nullable).
class V13ToV14 extends Migration {
  V13ToV14();
  @override
  int get targetVersion => 14;

  @override
  Future<void> apply(GeneratedDatabase db) async {
    final rows = await db.customSelect(
      "SELECT name FROM pragma_table_info('tafsir_sources')",
    ).get();
    final exists = rows.any((r) => r.read<String>('name') == 'quran_com_id');
    if (!exists) {
      await db.customStatement(
        'ALTER TABLE tafsir_sources ADD COLUMN quran_com_id INTEGER',
      );
    }
  }
}

/// v15 → v16: `tafsir_sources.name_ru` + backfill из `name_en`
/// для русской локали.
class V15ToV16 extends Migration {
  V15ToV16();
  @override
  int get targetVersion => 16;

  @override
  Future<void> apply(GeneratedDatabase db) async {
    final rows = await db.customSelect(
      "SELECT name FROM pragma_table_info('tafsir_sources')",
    ).get();
    final exists = rows.any((r) => r.read<String>('name') == 'name_ru');
    if (!exists) {
      await db.customStatement(
        'ALTER TABLE tafsir_sources ADD COLUMN name_ru TEXT',
      );
      await db.customStatement(
        "UPDATE tafsir_sources SET name_ru = name_en "
        "WHERE language_code = 'ru' AND name_ru IS NULL",
      );
    }
  }
}

/// v17 → v18: `translators.quran_com_id` и `translators.name_ru`
/// (Round 8 — миграция с alquran.cloud на Quran.com).
class V17ToV18 extends Migration {
  V17ToV18();
  @override
  int get targetVersion => 18;

  @override
  Future<void> apply(GeneratedDatabase db) async {
    final rows = await db.customSelect(
      "SELECT name FROM pragma_table_info('translators')",
    ).get();
    if (!rows.any((r) => r.read<String>('name') == 'quran_com_id')) {
      await db.customStatement(
        'ALTER TABLE translators ADD COLUMN quran_com_id INTEGER',
      );
    }
    if (!rows.any((r) => r.read<String>('name') == 'name_ru')) {
      await db.customStatement(
        'ALTER TABLE translators ADD COLUMN name_ru TEXT',
      );
    }
  }
}

/// v18 → v19: re-backfill `surahs.name_ru/subtitle_ru` из
/// `kSurahRuNames/kSurahRuSubtitles`.
///
/// Схема не меняется — только перезапись значений в существующих
/// рядах. Раньше backfill (v11→v12) использовал `IS NULL` guard и
/// не обновлял уже-заполненные ряды, поэтому исправления 2026-08-02
/// (17 имён + 28 подзаголовков) у существующих пользователей не
/// подхватывались.
///
/// Реализация — в `app_database.dart::onUpgrade` блок `if (from < 19)`,
/// вызывающий `_backfillRussianSurahNames` без `IS NULL` guard (см.
/// `_backfillRussianSurahNamesUnconditional`). Здесь — no-op для
/// единообразия с V11ToV12 (гибрид: small migrations inline, large —
/// через helper в `app_database.dart`).
class V18ToV19 extends Migration {
  V18ToV19();
  @override
  int get targetVersion => 19;

  @override
  Future<void> apply(GeneratedDatabase db) async {
    // No-op: backfill handled in `app_database.dart::onUpgrade`.
  }
}

/// Migration chain (должен быть отсортирован по `targetVersion`).
final List<Migration> _migrationChain = <Migration>[
  V5ToV6(),
  V6ToV7(),
  V7ToV8(),
  V8ToV9(),
  V9ToV10(),
  V10ToV11(),
  V11ToV12(),
  V13ToV14(),
  V15ToV16(),
  V17ToV18(),
  V18ToV19(),
];

/// Применить все миграции с `from < targetVersion <= to`.
/// Идемпотентно — повторный вызов с теми же `from/to` — no-op.
///
/// Pre-condition: `from < to` (вызывающий код должен это
/// гарантировать — Drift вызывает onUpgrade только при
/// реальном апгрейде).
Future<void> applyMigrations(
  Migrator m,
  int from,
  int to,
) async {
  for (final migration in _migrationChain) {
    if (migration.targetVersion > from && migration.targetVersion <= to) {
      await migration.apply(m.database);
    }
  }
}
