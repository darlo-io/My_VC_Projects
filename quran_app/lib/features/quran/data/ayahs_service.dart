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
  })  : _dao = ayahDao,
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
    if (state.value.isSyncing && state.value.surahId == surahId) {
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
    }

    return _fetchAndInsert(surahId);
  }

  /// Проверяет, есть ли аяты с page IS NULL для данной суры.
  /// Используется для решения — fetch или skip.
  Future<bool> _hasMissingMetadata(int surahId) async {
    // Используем drift query API (а не customSelect с Variable) — 
    // проще и без зависимости от drift Variable API.
    final query = _db.select(_db.ayahs)
      ..where((a) => a.surahId.equals(surahId) & a.page.isNull());
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

      final texts = results[0] as Map<String, QuranComAyahDto>;
      final metaMap = results[1] as Map<String, Map<String, int>>;

      if (texts.isEmpty && metaMap.isEmpty) {
        state.value = state.value.copyWith(
          stage: AyahsSyncStage.completed,
        );
        return state.value;
      }

      // 1. INSERT OR IGNORE metadata для всех аятов суры
      // customStatement принимает List<Object?> — raw values, не Variable.
      for (final entry in metaMap.entries) {
        final verseKey = entry.key;
        final meta = entry.value;
        final parts = verseKey.split(':');
        if (parts.length != 2) continue;
        final ayahNumber = int.tryParse(parts[1]);
        if (ayahNumber == null) continue;
        try {
          await _db.customStatement(
            'INSERT OR IGNORE INTO ayahs '
            '(surah_id, ayah_number, page, juz, hizb, '
            'text_uthmani, text_normalized) '
            'VALUES (?, ?, ?, ?, ?, ?, ?)',
            [
              surahId,
              ayahNumber,
              meta['page']!,
              meta['juz']!,
              meta['hizb']!,
              '',  // пустой text_uthmani
              '',  // пустой text_normalized
            ],
          );
        } catch (e, st) {
          developer.log(
            'insert metadata failed for $verseKey: $e',
            name: 'ayahs_service',
            error: e,
            stackTrace: st,
          );
        }
      }

      // 2. UPDATE text для всех аятов с fetched text
      var updated = 0;
      for (final entry in texts.entries) {
        final verseKey = entry.key;
        final dto = entry.value;
        final parts = verseKey.split(':');
        if (parts.length != 2) continue;
        final ayahNumber = int.tryParse(parts[1]);
        if (ayahNumber == null) continue;
        try {
          await _db.customStatement(
            'UPDATE ayahs SET text_uthmani = ?, text_normalized = ? '
            'WHERE surah_id = ? AND ayah_number = ?',
            [
              dto.textUthmani,
              dto.textUthmaniSimple,
              surahId,
              ayahNumber,
            ],
          );
          updated++;
        } catch (e) {
          developer.log(
            'update text failed for $verseKey: $e',
            name: 'ayahs_service',
          );
        }
      }

      developer.log(
        'fetched ${texts.length} verses, updated $updated for surahId=$surahId',
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

