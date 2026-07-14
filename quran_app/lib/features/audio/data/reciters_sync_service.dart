import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show ValueNotifier;

import 'reciters_repository.dart';

/// Состояние фоновой синхронизации списка чтецов с mp3quran.net.
///
/// Для UI: `RecitersSyncCard` (или snackbar в слушателе) может
/// показать прогресс. Используется в [RecitersSyncService.maybeSync].
enum RecitersSyncStage {
  idle, // нет в процессе, последний sync завершился (или его не было)
  checkingCache,
  running,
  completed,
  failed,
}

class RecitersSyncState {
  const RecitersSyncState({
    required this.stage,
    this.lastSyncedAt,
    this.error,
    this.insertedCount,
  });

  final RecitersSyncStage stage;
  final DateTime? lastSyncedAt;
  final Object? error;
  final int? insertedCount;

  bool get isRunning =>
      stage == RecitersSyncStage.checkingCache ||
      stage == RecitersSyncStage.running;

  /// Синхронизация при последнем запуске прошла успешно (или
  /// закончилась no-op из-за свежего кеша). Для показа «уже
  /// синхронизировано» в Info-карточке.
  bool get isUpToDate =>
      stage == RecitersSyncStage.idle && lastSyncedAt != null;

  static const idle = RecitersSyncState(stage: RecitersSyncStage.idle);

  RecitersSyncState copyWith({
    RecitersSyncStage? stage,
    DateTime? lastSyncedAt,
    Object? error,
    int? insertedCount,
  }) {
    return RecitersSyncState(
      stage: stage ?? this.stage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: error,
      insertedCount: insertedCount,
    );
  }
}

/// Фоновый воркер для синхронизации списка чтецов с mp3quran.net API.
///
/// Триггеры:
///   1. **Cold start** — `unawaited(recitersSyncService.maybeSync())`
///      из [ContentBootstrapper.bootstrap] сразу после `ensureSeeded`.
///   2. **Manual** — кнопка «Обновить список» в
///      [ReciterPickerScreen] вызывает [forceSync] (TTL игнорируется).
///   3. **(Phase 2) Workmanager** — периодический вызов раз в сутки,
///      чтобы вытащить кеш до истечения TTL.
///
/// Семантика кеша:
///   - [maybeSync] скипает sync если
///     `MAX(mp3quranCachedAt) - now < cacheTtl` **И** все ректоры в
///     БД уже имеют mp3quran-метаданные (`countRecitersWithoutMp3quranInfo == 0`).
///   - При первом запуске (после миграции v9→v10) у 8 дефолтных
///     ректоров есть cached_at (выставляется в `ensureSeeded`), но
///     `countWithoutMp3quranInfo == 0` всё равно — инициальный sync
///     подтянет оставшиеся ~233.
///   - Rate-limit не задокументирован у mp3quran.net, но один запрос
///     `/reciters?language=ar` — это один HTTP GET, payload ~100 KB
///     JSON. Держа 10 RPS на всякий случай — рекомендация та же,
///     что для AlQuran Cloud (см. AGENTS.md «Rate limiting»).
class RecitersSyncService {
  RecitersSyncService(this._repo);

  final RecitersRepository _repo;

  final ValueNotifier<RecitersSyncState> state =
      ValueNotifier(RecitersSyncState.idle);

  /// TTL кеша. Дефолт — 7 дней. Можно переопределить, например,
  /// для тестирования (поставить [Duration.zero]).
  static const _kDefaultCacheTtl = Duration(days: 7);

  /// Вызывается на каждом старте (после `ensureSeeded`).
  /// Skip'ает сетевой запрос если:
  ///   * Уже синхронизируемся (`state.isRunning`), ИЛИ
  ///   * Кеш свежий **И** все ректоры в БД уже синхронизированы.
  ///
  /// В противном случае запускает [forceSync].
  Future<void> maybeSync({Duration cacheTtl = _kDefaultCacheTtl}) async {
    if (state.value.isRunning) return;

    state.value = state.value.copyWith(
      stage: RecitersSyncStage.checkingCache,
      error: null,
    );
    try {
      final last = await _repo.latestMp3quranSync();
      final missing = await _repo.countRecitersWithoutMp3quranInfo();
      final freshEnough =
          last != null && DateTime.now().difference(last) < cacheTtl;
      if (freshEnough && missing == 0) {
        // Cache свежий, ничего не делаем.
        state.value = RecitersSyncState(
          stage: RecitersSyncStage.idle,
          lastSyncedAt: last,
        );
        developer.log(
          'reciters sync: cache fresh (age ${DateTime.now().difference(last)}'
          ', missing=$missing), skipping',
          name: 'reciters_sync',
        );
        return;
      }
      developer.log(
        'reciters sync: cache stale (last=$last, missing=$missing), '
        'starting sync',
        name: 'reciters_sync',
      );
    } catch (e) {
      developer.log(
        'reciters sync: cache check failed ($e), proceeding to sync',
        name: 'reciters_sync',
      );
    }
    await forceSync();
  }

  /// Принудительная синхронизация (обходит все проверки кеша).
  /// Используется из кнопки «Обновить список» в picker'е.
  Future<void> forceSync() async {
    state.value = state.value.copyWith(
      stage: RecitersSyncStage.running,
      error: null,
    );
    try {
      // Sprint 1.5d: dual-source sync. Сначала mp3quran (legacy),
      // потом Quran.com (новый источник). Если Quran.com упадёт —
      // приложение продолжит работать на mp3quran.
      final nMp3quran = await _repo.syncFromApi();
      int nQuranCom = 0;
      try {
        nQuranCom = await _repo.syncQuranComFromApi();
      } catch (qcError) {
        // Не критично: mp3quran работает, Quran.com — optional.
        developer.log(
          'quran_com sync failed (continuing with mp3quran only): $qcError',
          name: 'reciters_sync',
        );
      }
      // Дополнительно исправляем nameRu в БД для существующих
      // записей (override + fallback на nameEn для сломанных
      // значений вроде «Мшари Аль Ифаси» от id=123).
      final fixed = await _repo.applyNameOverrides();
      final total = nMp3quran + nQuranCom;
      state.value = RecitersSyncState(
        stage: RecitersSyncStage.completed,
        lastSyncedAt: DateTime.now(),
        insertedCount: total,
      );
      developer.log(
        'reciters sync: completed, mp3quran=$nMp3quran, '
        'quranCom=$nQuranCom, nameOverrides applied=$fixed',
        name: 'reciters_sync',
      );
    } catch (e, st) {
      developer.log(
        'reciters sync: failed: $e',
        name: 'reciters_sync',
        error: e,
        stackTrace: st,
      );
      state.value = RecitersSyncState(
        stage: RecitersSyncStage.failed,
        error: e,
      );
    }
  }
}