// Round 8 (2026-07-23): Lazy fetch переводов с Quran.com API.
//
// Вызывается при выборе нового translator'a в Settings. Если
// translations для него ещё не в БД — качает через
// `QuranComTranslationApi.fetchByChapter(translationId, chapterNumber)`
// для каждой из 114 сур, сохраняет через `TranslationDao.bulkInsertForTranslator`.
//
// **Архитектура**:
// - singleton через Riverpod (`quranTranslationSyncServiceProvider`)
// - `ValueNotifier<TranslationSyncState>` для UI прогресса
// - `ensureTranslatorLoaded(translatorId)` — non-blocking,
//   возвращает Future<TranslationSyncState> через Completer
// - Round 8 Этап 1 уже добавил `QuranComTranslationApi` и `translators`
//   колонку `quran_com_id`. Этот service использует их.

import 'dart:async';
import 'dart:developer' as developer;

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/translation_dao.dart';
import 'quran_com_translation_api.dart';

enum TranslationSyncStage { idle, syncing, completed, failed }

class TranslationSyncState {
  const TranslationSyncState({
    this.stage = TranslationSyncStage.idle,
    this.translatorId,
    this.totalSurahs = 114,
    this.completedSurahs = 0,
    this.errorMessage,
  });

  final TranslationSyncStage stage;
  final int? translatorId;
  final int totalSurahs;
  final int completedSurahs;
  final String? errorMessage;

  double get progress =>
      totalSurahs == 0 ? 0 : completedSurahs / totalSurahs;

  bool get isSyncing => stage == TranslationSyncStage.syncing;

  TranslationSyncState copyWith({
    TranslationSyncStage? stage,
    int? translatorId,
    int? totalSurahs,
    int? completedSurahs,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TranslationSyncState(
      stage: stage ?? this.stage,
      translatorId: translatorId ?? this.translatorId,
      totalSurahs: totalSurahs ?? this.totalSurahs,
      completedSurahs: completedSurahs ?? this.completedSurahs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class QuranTranslationSyncService {
  QuranTranslationSyncService({
    required TranslationDao translationDao,
    required QuranComTranslationApi api,
    required AppDatabase db,
  }) : _dao = translationDao,
       _api = api,
       _db = db;

  final TranslationDao _dao;
  final QuranComTranslationApi _api;
  final AppDatabase _db;

  final ValueNotifier<TranslationSyncState> state =
      ValueNotifier(const TranslationSyncState());

  /// Round 8: убеждаемся, что translations для [translatorId]
  /// загружены в БД. Если нет — качает в background.
  ///
  /// **Идемпотентно**: проверяет countForTranslator, если >0 —
  /// no-op. Если уже sync в процессе — возвращает тот же Future.
  Future<TranslationSyncState> ensureTranslatorLoaded(int translatorId) async {
    // Уже синхронизируется — дождаться.
    if (state.value.isSyncing && state.value.translatorId == translatorId) {
      return state.value;
    }

    // Проверяем, есть ли translations для translator'a.
    final existing = await _dao.countForTranslator(translatorId);
    if (existing > 0) {
      developer.log(
        'ensureTranslatorLoaded: translator=$translatorId already has $existing translations, skipping fetch',
        name: 'translation_sync',
      );
      return state.value;
    }

    // Найти quran_com_id для translator'a (через БД).
    final translator = await (_db.select(_db.translators)
          ..where((t) => t.id.equals(translatorId)))
        .getSingleOrNull();
    if (translator == null) {
      throw StateError('translator $translatorId not found in DB');
    }
    final quranComId = translator.quranComId ?? translator.id;
    return _fetchAllSurahs(quranComId: quranComId, translatorId: translatorId);
  }

  Future<TranslationSyncState> _fetchAllSurahs({
    required int quranComId,
    required int translatorId,
  }) async {
    var totalItems = 0;
    state.value = state.value.copyWith(
      stage: TranslationSyncStage.syncing,
      translatorId: translatorId,
      totalSurahs: 114,
      completedSurahs: 0,
      clearError: true,
    );

    developer.log(
      'start fetch translation id=$quranComId for translator=$translatorId',
      name: 'translation_sync',
    );

    try {
      for (int chapterNumber = 1; chapterNumber <= 114; chapterNumber++) {
        // Round 8 fix (2026-07-25): возвращает Map<ayahNumber, text>
        // (не Map<verseKey, text> как у tafsir). index+1 = ayah_number.
        final verses = await _api.fetchByChapter(
          translationId: quranComId,
          chapterNumber: chapterNumber,
        );

        if (verses.isNotEmpty) {
          // Build ayah_id lookup: WHERE surah_id = ? (drift-таблица
          // `ayahs` использует `surah_id`, не `surah_number`).
          // 1 SQL запрос на суру.
          final ayahRows = await _db.customSelect(
            'SELECT id, ayah_number FROM ayahs WHERE surah_id = ?',
            variables: [Variable.withInt(chapterNumber)],
            readsFrom: {_db.ayahs},
          ).get();
          final ayahMap = <int, int>{
            for (final r in ayahRows)
              r.read<int>('ayah_number'): r.read<int>('id'),
          };

          final items = <({int ayahId, String text})>[];
          verses.forEach((ayahNumber, text) {
            final ayahId = ayahMap[ayahNumber];
            if (ayahId != null) items.add((ayahId: ayahId, text: text));
          });

          if (items.isNotEmpty) {
            totalItems += items.length;
            await _dao.bulkInsertForTranslator(
              translatorId: translatorId,
              items: items,
            );
          }
        }

        state.value = state.value.copyWith(completedSurahs: chapterNumber);
      }

      state.value = state.value.copyWith(stage: TranslationSyncStage.completed);
      developer.log(
        'completed fetch translation id=$quranComId for translator=$translatorId, total items: $totalItems',
        name: 'translation_sync',
      );
      return state.value;
    } catch (e, st) {
      developer.log(
        'fetch translation id=$quranComId FAILED',
        name: 'translation_sync',
        error: e,
        stackTrace: st,
      );
      state.value = state.value.copyWith(
        stage: TranslationSyncStage.failed,
        errorMessage: e.toString(),
      );
      return state.value;
    }
  }
}
