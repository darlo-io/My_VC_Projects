// Round 9.2 (2026-07-25): lazy load аятов с Quran.com API.
//
// Стратегия: 2 параллельных запроса на суру:
// 1. /quran/verses/uthmani?chapter_number=N     → text_uthmani, textUthmaniSimple (с диакритикой и без)
// 2. /verses/by_chapter/N                       → page, juz, hizb (metadata)
//
// merge → INSERT OR IGNORE (если нет в БД) для metadata,
// UPDATE text_uthmani/text_normalized для текста.
//
// Используется в ReaderScreen через ref.watch.

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show ValueNotifier;

// Импортируем расширение, которое даёт `&` (Bitwise AND) для Expression<bool>.
// Без него dart неявно резолвит `&` как bitwise int operator, который
// возвращает `int` а не `Expression<bool>`, что и приводит к ошибке
// `A value of type 'Expression<bool>' can't be assigned to a variable of type 'bool'`.
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/ayah_dao.dart';
import '../../audio/data/quran_com_api.dart';

enum AyahsSyncStage { idle, syncing, completed, failed }

class AyahsSyncState {
  const AyahsSyncState({
    this.stage = AyahsSyncStage.idle,
    this.surahId,
    this.completedAyahs = 0,
    this.errorMessage,
  });

  final AyahsSyncStage stage;
  final int? surahId;
  final int completedAyahs;
  final String? errorMessage;

  bool get isSyncing => stage == AyahsSyncStage.syncing;

  AyahsSyncState copyWith({
    AyahsSyncStage? stage,
    int? surahId,
    int? completedAyahs,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AyahsSyncState(
      stage: stage ?? this.stage,
      surahId: surahId ?? this.surahId,
      completedAyahs: completedAyahs ?? this.completedAyahs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AyahsService {
  AyahsService({
    required AyahDao ayahDao,
    required QuranComApi quranComApi,
    required AppDatabase db,
  }) : _dao = ayahDao,
       _api = quranComApi,
       _db = db;

  final AyahDao _dao;
  final QuranComApi _api;
  final AppDatabase _db;

  /// Round 9.2: reactive state для UI прогресса lazy fetch.
  final ValueNotifier<AyahsSyncState> state =
      ValueNotifier(const AyahsSyncState());

  /// Round 9.2: убеждаемся, что аяты для [surahId] загружены в БД.
  /// **Идемпотентно**: если в БД уже есть аяты — no-op.
  /// Иначе — fetch с Quran.com + bulk insert.
  Future<AyahsSyncState> ensureLoaded(int surahId) async {
    developer.log(
      'ensureLoaded START surahId=$surahId',
      name: 'ayahs_service',
    );
    if (state.value.isSyncing && state.value.surahId == surahId) {
      developer.log(
        'ensureLoaded: already syncing, skip',
        name: 'ayahs_service',
      );
      return state.value;
    }

    final existing = await _dao.countAyahs(surahId);
    developer.log(
      'ensureLoaded: surahId=$surahId existing=$existing',
      name: 'ayahs_service',
    );

    // Lazy load logic:
    // 1. countAyahs == 0 — fetch с Quran.com (cold install)
    // 2. countAyahs > 0, но page IS NULL — fetch (cold install
    //    через quran_full.json, не содержал page/juz/hizb)
    // 3. countAyahs > 0 и все аяты имеют page — skip
    if (existing > 0) {
      final needsMetadata = await _hasMissingMetadata(surahId);
      developer.log(
        'ensureLoaded: surahId=$surahId needsMetadata=$needsMetadata',
        name: 'ayahs_service',
      );
      if (!needsMetadata) {
        developer.log(
          'ensureLoaded: surahId=$surahId already loaded with metadata, skip',
          name: 'ayahs_service',
        );
        return state.value;
      }
      developer.log(
        'ensureLoaded: surahId=$surahId has ayahs but missing page/juz/hizb, fetching',
        name: 'ayahs_service',
      );
    } else {
      developer.log(
        'ensureLoaded: cold install, fetching all verses for surahId=$surahId',
        name: 'ayahs_service',
      );
    }

    return _fetchAndInsert(surahId);
  }

  /// Проверяет, есть ли аяты с page IS NULL для данной суры.
  /// Используется для решения — fetch или skip.
  Future<bool> _hasMissingMetadata(int surahId) async {
    // Drift 2.x: оператор `&&` возвращает bool, а `..where` ждет
    // Expression<bool>. Решение — разбить на два .where():
    final query = _db.select(_db.ayahs)
      ..where((a) => a.surahId.equals(surahId))
      ..where((a) => a.page.isNull());
    final count = await query.get().then((rows) => rows.length);
    return count > 0;
  }

  Future<AyahsSyncState> _fetchAndInsert(int surahId) async {
    state.value = state.value.copyWith(
      stage: AyahsSyncStage.syncing,
      surahId: surahId,
      completedAyahs: 0,
      clearError: true,
    );

    developer.log(
      'start fetch ayahs for surahId=$surahId',
      name: 'ayahs_service',
    );

    try {
      // Параллельный fetch: text (uthmani + simple) + metadata
      // (page, juz, hizb через /verses/by_chapter).
      final textsFuture = _api.fetchVersesByChapter(
        chapterNumber: surahId,
      );
      final metaFuture = _api.fetchAyahMetadataByChapter(
        chapterNumber: surahId,
      );
      final results = await Future.wait([textsFuture, metaFuture]);

      final texts = (results[0] as Map<String, QuranComAyahDto>?) ?? const {};
      final metaMap = (results[1] as Map<String, Map<String, int>>?) ??
          const <String, Map<String, int>>{};

      if (texts.isEmpty && metaMap.isEmpty) {
        state.value = state.value.copyWith(
          stage: AyahsSyncStage.completed,
        );
        return state.value;
      }

      // 1. Batch UPDATE metadata для существующих аятов (по surah_id +
      // ayah_number). Round 9.5 (code review #C2): заменили N отдельных
      // await customStatement на batch(), что сокращает латентность для
      // больших сур (Бакара = 286 итераций → 1 round-trip в SQLite).
      // Не INSERT OR IGNORE — у таблицы `ayahs` нет UNIQUE constraint
      // на (surah_id, ayah_number), только PRIMARY KEY на id. INSERT
      // OR IGNORE создаёт дубликаты при наличии строки с тем же
      // (surah_id, ayah_number). Используем UPDATE чтобы перезаписать
      // page/juz/hizb без создания дубликатов. customStatement
      // принимает List<Object?> — raw values, не Variable.
      //
      // На провале любого statement в batch() — вся транзакция
      // откатывается (Drift гарантирует). Failure → exception
      // ловится во внешнем try/catch.
      await _db.batch((batch) {
        for (final entry in metaMap.entries) {
          final verseKey = entry.key;
          final meta = entry.value;
          final parts = verseKey.split(':');
          if (parts.length != 2) continue;
          final ayahNumber = int.tryParse(parts[1]);
          if (ayahNumber == null) continue;
          final page = meta['page'];
          final juz = meta['juz'];
          final hizb = meta['hizb'];
          if (page == null || juz == null || hizb == null) continue;
          batch.customStatement(
            'UPDATE ayahs SET page = ?, juz = ?, hizb = ? '
            'WHERE surah_id = ? AND ayah_number = ?',
            [page, juz, hizb, surahId, ayahNumber],
          );
        }
      });

      // 2. Batch UPDATE text для всех аятов с fetched text. Аналогично
      // пункту 1 — один round-trip вместо N.
      await _db.batch((batch) {
        for (final entry in texts.entries) {
          final verseKey = entry.key;
          final dto = entry.value;
          final parts = verseKey.split(':');
          if (parts.length != 2) continue;
          final ayahNumber = int.tryParse(parts[1]);
          if (ayahNumber == null) continue;
          batch.customStatement(
            'UPDATE ayahs SET text_uthmani = ?, text_normalized = ? '
            'WHERE surah_id = ? AND ayah_number = ?',
            [dto.textUthmani, dto.textUthmaniSimple, surahId, ayahNumber],
          );
        }
      });

      developer.log(
        'fetched ${texts.length} verses, batch-updated for surahId=$surahId',
        name: 'ayahs_service',
      );

      state.value = state.value.copyWith(
        stage: AyahsSyncStage.completed,
        completedAyahs: texts.length,
      );
      return state.value;
    } catch (e, st) {
      developer.log(
        'fetch ayahs for surahId=$surahId FAILED',
        name: 'ayahs_service',
        error: e,
        stackTrace: st,
      );
      state.value = state.value.copyWith(
        stage: AyahsSyncStage.failed,
        errorMessage: e.toString(),
      );
      return state.value;
    }
  }
}

