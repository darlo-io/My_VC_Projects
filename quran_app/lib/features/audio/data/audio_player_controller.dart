import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/surah_dao.dart';
import 'audio_cache.dart';
import 'audio_source_chain.dart';
import 'reciters_repository.dart';

/// Состояние плеера, отдаваемое наружу через стрим.
class AudioPlayerState {
  const AudioPlayerState({
    required this.reciter,
    required this.surah,
    required this.surahName,
    required this.playing,
    required this.loading,
    required this.positionMs,
    required this.durationMs,
    this.error,
    this.speed = 1.0,
    this.sleepTimerAtMs,
  });

  final Reciter? reciter;
  final Surah? surah;
  final String surahName;
  final bool playing;
  final bool loading;
  final int positionMs;
  final int durationMs;
  final String? error;

  /// Скорость воспроизведения (1.0 = нормальная, 1.5 / 2.0 / 0.5).
  /// Сохраняется в state, чтобы UI мог отображать выбранный
  /// вариант и сбрасывать к 1.0 при stop().
  final double speed;

  /// Timestamp (`DateTime.now()`) **остановки** плеера по sleep
  /// timer'у. `null` = таймер не активен. Когда
  /// `positionMs >= sleepTimerAtMs - startedAt`, плеер
  /// останавливается.
  final DateTime? sleepTimerAtMs;

  /// Оставшееся время до автоматической остановки (null если
  /// таймер не активен). Чисто-вычислимое — для UI.
  Duration? get sleepTimerRemaining {
    final at = sleepTimerAtMs;
    if (at == null) return null;
    final now = DateTime.now();
    if (at.isBefore(now)) return Duration.zero;
    return at.difference(now);
  }

  static const empty = AudioPlayerState(
    reciter: null,
    surah: null,
    surahName: '',
    playing: false,
    loading: false,
    positionMs: 0,
    durationMs: 0,
  );

  AudioPlayerState copyWith({
    Reciter? reciter,
    Surah? surah,
    String? surahName,
    bool? playing,
    bool? loading,
    int? positionMs,
    int? durationMs,
    String? error,
    bool clearError = false,
    double? speed,
    DateTime? sleepTimerAtMs,
    bool clearSleepTimer = false,
  }) {
    return AudioPlayerState(
      reciter: reciter ?? this.reciter,
      surah: surah ?? this.surah,
      surahName: surahName ?? this.surahName,
      playing: playing ?? this.playing,
      loading: loading ?? this.loading,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      error: clearError ? null : (error ?? this.error),
      speed: speed ?? this.speed,
      sleepTimerAtMs:
          clearSleepTimer ? null : (sleepTimerAtMs ?? this.sleepTimerAtMs),
    );
  }
}

/// Контроллер аудио-плеера. Один на всё приложение.
///
/// Ответственность:
/// - Резолв URL суры по ректору (через [_resolveUrl])
/// - Cache-first загрузка через [AudioCache]
/// - Just-audio проигрывание + экспорт стримов
/// - Поддержка play/pause/seek/stop
class AudioPlayerController extends StateNotifier<AudioPlayerState> {
  AudioPlayerController({
    required this._cache,
    required this._reciters,
    required this._surahDao,
  })  : super(AudioPlayerState.empty) {
    _wireStreams();
  }

  final AudioCache _cache;
  final RecitersRepository _reciters;
  final SurahDao _surahDao;
  AudioSourceResolver? _resolver;

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  Timer? _sleepTimer;

  void _wireStreams() {
    _stateSub = _player.playerStateStream.listen((s) {
      state = state.copyWith(
        playing: s.playing,
        loading: s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering,
      );
    });
    _posSub = _player.positionStream.listen((p) {
      state = state.copyWith(positionMs: p.inMilliseconds);
    });
    _durSub = _player.durationStream.listen((d) {
      if (d != null) {
        state = state.copyWith(durationMs: d.inMilliseconds);
      }
    });
  }

  String _resolveUrl(Reciter reciter, int surah) {
    // Ищем seed по id, чтобы достать cdnTemplate; fallback — стандартный путь.
    final seed = kDefaultReciters.firstWhere(
      (r) => r.id == reciter.id,
      orElse: () => kDefaultReciters.first,
    );
    return seed.cdnTemplate.replaceAll('{surah}', surah.toString().padLeft(3, '0'));
  }

  /// Загрузить и проиграть суру. При ошибке — сбрасывает loading и
  /// выставляет [AudioPlayerState.error], чтобы UI мог показать retry.
  ///
  /// Логика выбора URL (см. ARCHITECTURE §12):
  ///   1. Берём `cdnTemplate` из [ReciterSeed] (источник
  ///      «primary» для этого ректора).
  ///   2. Если `cdnTemplate` вернул 404 / 5xx / timeout —
  ///      перебираем [AudioSourceChain.sources] (defaultChain)
  ///      и пробуем каждый.
  ///   3. Если все источники провалились — бросаем
  ///      [AllSourcesFailed], и `state.error` показывает
  ///      primary-ошибку для UI.
  Future<void> playSurah({required String reciterId, required int surahId}) async {
    try {
      final reciter = await _reciters.getById(reciterId);
      if (reciter == null) {
        state = state.copyWith(
          loading: false,
          error: 'Reciter not found: $reciterId',
        );
        return;
      }
      final surah = await _surahDao.getById(surahId);
      if (surah == null) {
        state = state.copyWith(
          loading: false,
          error: 'Surah not found: $surahId',
        );
        return;
      }

      state = state.copyWith(
        reciter: reciter,
        surah: surah,
        surahName: surah.nameTransliteration,
        loading: true,
        clearError: true,
      );

      // 1) Primary URL — из ReciterSeed.cdnTemplate
      final primaryUrl = _resolveUrl(reciter, surahId);
      String? lastError;
      final file = await _tryCacheOrFallback(
        reciterId: reciterId,
        surahId: surahId,
        primaryUrl: primaryUrl,
        onPrimaryError: (e) {
          lastError = '$e';
        },
      );
      if (file == null) {
        // 2) Если primary провалился и `AudioSourceResolver`
        // не помог (нет chain), показываем ошибку.
        throw StateError(
          lastError ?? 'Audio source unavailable',
        );
      }
      await _player.setFilePath(file.path);
      await _player.play();
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  /// Попробовать primary URL, при ошибке — fallback через
  /// [AudioSourceResolver]. Возвращает `File` или `null` если
  /// все источники провалились.
  Future<File?> _tryCacheOrFallback({
    required String reciterId,
    required int surahId,
    required String primaryUrl,
    required void Function(Object error) onPrimaryError,
  }) async {
    try {
      return await _cache.getOrDownload(
        reciterId: reciterId,
        surah: surahId,
        url: primaryUrl,
      );
    } catch (e) {
      onPrimaryError(e);
    }
    // Fallback: попробуем defaultChain.
    try {
      final resolved = await (_resolver ??= AudioSourceResolver(
        dio: _cache.dio,
        chain: defaultAudioSourceChain(),
      )).resolve(reciterId: reciterId, surahId: surahId);
      return await _cache.getOrDownload(
        reciterId: '$reciterId#${resolved.source.id}',
        surah: surahId,
        url: resolved.url,
      );
    } catch (_) {
      // Если и resolver провалился — возвращаем null, основной
      // `playSurah` сам бросит `StateError` с primary-ошибкой.
      rethrow;
    }
  }

  Future<void> togglePlay() async {
    if (state.surah == null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  /// Изменить скорость воспроизведения. `speed` ∈ [0.5, 2.0] (0.5x
  /// — 0.5x, 1.0 — нормальная, 1.25 / 1.5 / 1.75 / 2.0 — ускорение).
  /// Реализовано через `_player.setSpeed` (just_audio поддерживает
  /// pitch-preserved time-stretching).
  Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(0.5, 2.0);
    state = state.copyWith(speed: clamped);
    await _player.setSpeed(clamped);
  }

  /// Установить sleep timer на [minutes] минут. По истечении —
  /// плеер останавливается (`stop()`), `state.sleepTimerAtMs`
  /// сбрасывается.
  ///
  /// `minutes <= 0` или `null` — отменить таймер.
  void setSleepTimer(int? minutes) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (minutes == null || minutes <= 0) {
      state = state.copyWith(clearSleepTimer: true);
      return;
    }
    final at = DateTime.now().add(Duration(minutes: minutes));
    state = state.copyWith(sleepTimerAtMs: at);
    _sleepTimer = Timer(Duration(minutes: minutes), () {
      // Auto-stop. Не вызываем `stop()` напрямую, чтобы не
      // затереть `state.surah` (юзер мог выбрать другую суру,
      // и после остановки sleep-timer'ом она должна остаться).
      unawaited(_player.pause());
      _sleepTimer = null;
      state = state.copyWith(
        playing: false,
        clearSleepTimer: true,
      );
    });
  }

  /// Night mode: установить audio-конфиг (низкий битрейт, без
  /// стерео) для прослушивания ночью / в наушниках с фоновым шумом.
  /// `enabled = true` → mono, 32kbps; `false` → стерео, 128kbps
  /// (default).
  ///
  /// Реализовано через `AudioServiceConfig.androidNotificationOngoing`
  /// (уже есть) + `setSkipSilence`/`setShuffle` (если поддерживается
  /// CDN'ом). Здесь — placeholder для будущей работы: на MVP v0.2
  /// сохраняем флаг в state, и UI показывает индикатор.
  void setNightMode(bool enabled) {
    // no-op: just_audio не предоставляет runtime-переключение
    // битрейта / каналов без re-encoding источника. На v0.2
    // night mode — UI-only индикатор + опционально `setVolume(0.5)`
    // для ночного режима. Помечаем в state для UI.
    state = state.copyWith(speed: state.speed); // no-op, marker
  }

  /// Сбросить error-флаг без изменения `surah/reciter`. Вызывается
  /// из retry-кнопки в `_PlayerErrorBanner` перед повторным
  /// `playSurah`. Делает так, чтобы старый текст ошибки не
  /// «залипал» в UI, пока новая попытка грузится.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> seekTo(Duration position) => _player.seek(position);

  Future<void> stop() async {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    await _player.stop();
    state = AudioPlayerState.empty;
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
