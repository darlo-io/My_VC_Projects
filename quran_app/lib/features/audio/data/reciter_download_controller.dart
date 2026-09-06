import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'audio_cache.dart';
import 'reciters_repository.dart';

/// Состояние одной in-flight загрузки «все суры для ректора».
///
/// State-машина:
///   idle — никто не качает
///   downloading(reciterId, completed, total) — идёт загрузка
///   failed(reciterId, error) — последняя попытка упала (юзер может retry)
class ReciterDownloadState {
  const ReciterDownloadState.idle()
      : reciterId = null,
        completed = 0,
        total = 0,
        error = null,
        _kind = _Kind.idle;

  const ReciterDownloadState.downloading({
    required this.reciterId,
    required this.completed,
    required this.total,
  })  : error = null,
        _kind = _Kind.downloading;

  const ReciterDownloadState.failed({
    required this.reciterId,
    required this.error,
  })  : completed = 0,
        total = 0,
        _kind = _Kind.failed;

  final String? reciterId;
  final int completed;
  final int total;
  final String? error;
  final _Kind _kind;

  bool get isIdle => _kind == _Kind.idle;
  bool get isDownloading => _kind == _Kind.downloading;
  bool get isFailed => _kind == _Kind.failed;

  bool isDownloadingReciter(String id) =>
      isDownloading && reciterId == id;

  ReciterDownloadState copyWith({
    String? reciterId,
    int? completed,
    int? total,
    String? error,
  }) {
    if (error != null) {
      return ReciterDownloadState.failed(reciterId: reciterId ?? '', error: error);
    }
    if (reciterId != null) {
      return ReciterDownloadState.downloading(
        reciterId: reciterId,
        completed: completed ?? 0,
        total: total ?? 0,
      );
    }
    return const ReciterDownloadState.idle();
  }
}

enum _Kind { idle, downloading, failed }

/// Контроллер загрузки «все MP3 для ректора».
///
/// Singleton (через провайдер): у него один слот загрузки, чтобы
/// не повесить устройство параллельными запросами к mp3quran.net.
/// При тапе по другому ректору во время загрузки — текущая отменяется
/// через [CancelToken], стартует новая.
class ReciterDownloadController extends StateNotifier<ReciterDownloadState> {
  ReciterDownloadController({
    required this._cache,
    required this._reciters,
  })  : super(const ReciterDownloadState.idle());

  final AudioCache _cache;
  final RecitersRepository _reciters;
  CancelToken? _cancel;

  /// Запустить загрузку всех 114 MP3 для [reciter].
  ///
  /// Если уже идёт загрузка другого ректора — она отменяется.
  /// Если этот же ректор уже качается — no-op (UI должен скрывать
  /// иконку в этом состоянии, поэтому попадание сюда маловероятно).
  ///
  /// Оптимизации скорости (по сравнению со старой версией):
  ///   1. Уже скачанные суры пропускаются через `isCached`. Старая
  ///      версия перекачивала все 114 — даже если 113 уже на диске.
  ///   2. Параллельные скачивания (concurrency 3) — три суры
  ///      скачиваются одновременно. mp3quran.net не публикует
  ///      rate-limit, но AlQuran Cloud документа — 10 RPS. С 3
  ///      одновременными коннектами мы остаёмся ниже 10 RPS при
  ///      типичной латентности > 300ms.
  ///   3. Нет `Future.delayed(100ms)` между сурами — старый 100ms-
  ///      паддинг добавлял ~12s оверхеда на 114 сур.
  Future<void> startDownload(String reciterId) async {
    if (state.isDownloadingReciter(reciterId)) return;

    // Отменяем предыдущую загрузку, если была.
    _cancel?.cancel('superseded by $reciterId');
    final cancel = CancelToken();
    _cancel = cancel;

    state = ReciterDownloadState.downloading(
      reciterId: reciterId,
      completed: 0,
      total: 0, // определим ниже
    );

    try {
      final reciter = await _reciters.getById(reciterId);
      if (reciter == null) {
        state = ReciterDownloadState.failed(
          reciterId: reciterId,
          error: 'Reciter not found',
        );
        return;
      }

      // Собираем список сур к скачиванию. mp3quran гарантирует
      // 114 для Hafs; moshaf.surahTotal может быть меньше для
      // других rewaya — берём реальное число.
      //
      // Кандидаты URL через [resolveSurahUrlCandidates] (Quran.com →
      // mp3quran): ключ кеша `{reciterId}/{surah}` один и тот же для
      // обоих CDN — контент идентичен, так что prefetch и playback
      // консистентны.
      final total = reciter.mp3quranSurahTotal ?? 114;
      final toDownload = <int>[];
      for (var s = 1; s <= total; s++) {
        if (resolveSurahUrlCandidates(reciter, s).isEmpty) {
          continue; // reciter без mp3quran-метаданных
        }
        if (await _cache.isCached(reciterId: reciterId, surah: s)) continue;
        toDownload.add(s);
      }

      // Если все суры уже в кеше — выходим сразу, idle state.
      if (toDownload.isEmpty) {
        state = const ReciterDownloadState.idle();
        return;
      }

      // Параллельно качаем с concurrency 3. Каждая итерация
      // обновляет state.completed для UI spinner'а.
      var completed = 0;
      const concurrency = 3;
      final pending = List<int>.from(toDownload);

      state = ReciterDownloadState.downloading(
        reciterId: reciterId,
        completed: 0,
        total: toDownload.length,
      );

      Future<void> worker() async {
        while (pending.isNotEmpty) {
          if (cancel.isCancelled) return;
          if (pending.isEmpty) return;
          final surah = pending.removeAt(0);
          // Перебор кандидатов: первый успешный источник качает файл.
          // 404 на устаревшем Quran.com-маппинге не валит суру —
          // уходим на mp3quran-фоллбэк (проверка 2026-08).
          var downloaded = false;
          Object? lastError;
          for (final url in resolveSurahUrlCandidates(reciter, surah)) {
            if (cancel.isCancelled) return;
            try {
              // getOrDownloadNoEvict — НЕ запускает evictIfNeeded
              // (см. AudioCache.getOrDownloadNoEvict). Eviction
              // сделаем single-shot после всего prefetch'а ниже.
              await _cache.getOrDownloadNoEvict(
                reciterId: reciterId,
                surah: surah,
                url: url,
                cancelToken: cancel,
              );
              downloaded = true;
              break;
            } catch (e) {
              if (cancel.isCancelled) return;
              lastError = e;
            }
          }
          if (!downloaded && lastError != null) {
            // Одна сура упала на всех источниках — продолжаем остальные.
            developer.log(
              'prefetch: surah $surah failed on all sources',
              name: 'ReciterDownloadController',
              error: lastError,
            );
          }
          completed += 1;
          if (!cancel.isCancelled) {
            state = ReciterDownloadState.downloading(
              reciterId: reciterId,
              completed: completed,
              total: toDownload.length,
            );
          }
        }
      }

      // Запускаем `concurrency` воркеров, ждём всех.
      await Future.wait(List.generate(concurrency, (_) => worker()));

      if (cancel.isCancelled) return;
      // Eviction — single-shot после всего prefetch'а, в фоне,
      // чтобы не блокировать UI. Если лимит кеша превышен — вытеснит
      // LRU-непроигранные сурЫ, не трогая только-что-вставленные.
      unawaited(_cache.evictIfNeededNow());
      // Готово. UI пересоберёт isDone через fullyCachedRecitersProvider.
      state = const ReciterDownloadState.idle();
    } catch (e) {
      if (cancel.isCancelled) return;
      state = ReciterDownloadState.failed(reciterId: reciterId, error: '$e');
    }
  }

  /// Принудительно отменить текущую загрузку (например, при
  /// unmount'е экрана). [reason] — для логов.
  void cancel({String reason = 'user-cancelled'}) {
    if (!state.isDownloading) return;
    _cancel?.cancel(reason);
    state = const ReciterDownloadState.idle();
  }

  @override
  void dispose() {
    _cancel?.cancel('controller-dispose');
    super.dispose();
  }
}
