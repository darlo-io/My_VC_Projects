import 'dart:async';

import 'package:audio_service/audio_service.dart';

import 'audio_player_controller.dart';

/// Singleton [BaseAudioHandler] для [audio_service].
///
/// Оборачивает существующий [AudioPlayerController] (который владеет
/// `just_audio.AudioPlayer` и Drift-backed `AudioCache`) и отдаёт
/// `audio_service` свой `playbackState` и `mediaItem` для:
///   - нотификации в шторке (с play/pause/stop кнопками)
///   - lock-screen / Bluetooth-контролов
///   - фонового воспроизведения после сворачивания приложения
///
/// Жизненный цикл:
///   1. [AudioService.init] в main.dart создаёт handler через `builder: QuranAudioHandler.new`
///   2. После сборки Riverpod-графа вызывается [attach] с реальным
///      [AudioPlayerController]
///   3. Handler подписывается на `controller.stream` и бродкастит
///      изменения в [playbackState] / [mediaItem]
class QuranAudioHandler extends BaseAudioHandler {
  QuranAudioHandler();

  AudioPlayerController? _controller;
  AudioPlayerState _lastState = AudioPlayerState.empty;

  /// Привязать handler к контроллеру. Вызывается однократно после
  /// [AudioService.init] и сборки Riverpod-графа в main.dart.
  void attach(AudioPlayerController controller) {
    _controller = controller;
    // Fire-and-forget subscription: the handler lives for the entire
    // app lifetime and the underlying stream is closed when the
    // controller is disposed. The initial broadcast happens on the
    // first stream emission.
    controller.stream.listen((s) {
      _lastState = s;
      _broadcast(s);
    });
  }

  void _broadcast(AudioPlayerState s) {
    final processing = s.loading
        ? AudioProcessingState.loading
        : (s.error != null
            ? AudioProcessingState.error
            : AudioProcessingState.ready);
    playbackState.add(playbackState.value.copyWith(
      controls: const [
        MediaControl.stop,
        MediaControl.pause,
        MediaControl.play,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: processing,
      playing: s.playing,
      updatePosition: Duration(milliseconds: s.positionMs),
      bufferedPosition: Duration(milliseconds: s.durationMs),
      speed: 1.0,
      queueIndex: 0,
    ));

    if (s.surah != null) {
      mediaItem.add(MediaItem(
        id: 'quran/${s.reciter?.id ?? "default"}/${s.surah!.id}',
        album: 'Коран',
        title: s.surahName,
        artist: s.reciter?.nameEn ?? '',
        duration: s.durationMs > 0
            ? Duration(milliseconds: s.durationMs)
            : null,
      ));
    } else {
      mediaItem.add(null);
    }
  }

  /// Запустить суру (entry-point из app-кода).
  Future<void> playSurah({required String reciterId, required int surahId}) {
    final c = _requireController();
    return c.playSurah(reciterId: reciterId, surahId: surahId);
  }

  @override
  Future<void> play() => _requireController().togglePlay();

  @override
  Future<void> pause() => _requireController().togglePlay();

  @override
  Future<void> stop() async {
    await _requireController().stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) =>
      _requireController().seekTo(position);

  @override
  Future<void> fastForward() => _requireController().seekTo(
        Duration(milliseconds: _lastState.positionMs + 10000),
      );

  @override
  Future<void> rewind() => _requireController().seekTo(
        Duration(
          milliseconds: (_lastState.positionMs - 10000).clamp(0, 1 << 31),
        ),
      );

  AudioPlayerController _requireController() {
    final c = _controller;
    if (c == null) {
      throw StateError('QuranAudioHandler.attach() must be called '
          'before any playback operation.');
    }
    return c;
  }
}
