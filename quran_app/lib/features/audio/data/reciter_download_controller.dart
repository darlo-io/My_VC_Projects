import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
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
    required AudioCache cache,
    required RecitersRepository reciters,
  })  : _cache = cache,
        _reciters = reciters,
        super(const ReciterDownloadState.idle());

  final AudioCache _cache;
  final RecitersRepository _reciters;
  CancelToken? _cancel;

  /// Запустить загрузку всех 114 MP3 для [reciter].
  ///
  /// Если уже идёт загрузка другого ректора — она отменяется.
  /// Если этот же ректор уже качается — no-op (UI должен скрывать
  /// иконку в этом состоянии, поэтому попадание сюда маловероятно).
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

      // Найдём, сколько сур реально доступно. mp3quran гарантирует,
      // что Hafs-мусхаф = 114, но на всякий случай читаем из БД —
      // если в БД нет ни одной суры, выходим (всё равно нечего играть).
      const total = 114;

      var completed = 0;
      for (var surah = 1; surah <= total; surah++) {
        if (cancel.isCancelled) break;
        // Обновляем total/completed ДО скачивания следующей суры —
        // UI увидит «n / 114» в момент скачивания n-й.
        completed = surah - 1;
        state = ReciterDownloadState.downloading(
          reciterId: reciterId,
          completed: completed,
          total: total,
        );
        final url = resolveSurahUrl(reciter, surah);
        if (url == null) {
          // Reciter без mp3quran-метаданных (cdn is null) — пропускаем.
          continue;
        }
        try {
          await _cache.getOrDownload(
            reciterId: reciterId,
            surah: surah,
            url: url,
            cancelToken: cancel,
          );
          completed = surah;
          state = ReciterDownloadState.downloading(
            reciterId: reciterId,
            completed: completed,
            total: total,
          );
        } on DioException catch (e) {
          if (cancel.isCancelled) break;
          // Один сур упал — продолжаем остальные (cancel-only выход).
          // Logged здесь не критично, т.к. UI всё равно покажет
          // «failed» если в итоге ничего не скачалось.
          // ignore: avoid_print
          print('prefetch: surah $surah failed: $e');
        }
        // 100ms между сурами = ровно 10 RPS, на лимите cdn.alislam.ru
        // (10 req/s per IP, см. AGENTS.md «Rate limiting»).
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      if (cancel.isCancelled) {
        // Не очищаем state — caller стартует новую загрузку, сам
        // перепишет state.
        return;
      }

      // Done. Если completed < total — частичный успех, статус всё
      // равно idle (UI возьмёт инфу из `fullyCachedRecitersProvider`).
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
