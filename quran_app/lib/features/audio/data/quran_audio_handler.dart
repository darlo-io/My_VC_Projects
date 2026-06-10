import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';

import '../../../l10n/generated/app_localizations.dart';
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
  StreamSubscription<AudioPlayerState>? _stateSub;

  /// Кеш локализованной строки `mediaAlbum` для текущей локали.
  /// Перечитывается, если в `WidgetsBinding` сменился `locale`.
  String? _cachedAlbum;
  String? _cachedAlbumLocale;

  /// Привязать handler к контроллеру. Вызывается однократно после
  /// [AudioService.init] и сборки Riverpod-графа в main.dart.
  void attach(AudioPlayerController controller) {
    _controller = controller;
    // Subscription хранится явно, чтобы избежать потенциальной
    // утечки при перепривязке. На практике attach вызывается
    // ровно один раз за app-сессию, но `dispose()` теперь чистый.
    _stateSub?.cancel();
    _stateSub = controller.stream.listen((s) {
      _lastState = s;
      _broadcast(s);
    });
  }

  /// Подгрузить локализованный «album» для нотификации/lock-screen.
  /// Handler живёт за пределами widget tree, поэтому берём активную
  /// локаль из `WidgetsBinding` и через `AppLocalizations.delegate.load`
  /// получаем сгенерированный инстанс. Результат кешируется, чтобы
  /// не дёргать async-код на каждом broadcast.
  Future<String> _album() async {
    final code = WidgetsBinding
            .instance.platformDispatcher.locale.languageCode;
    if (_cachedAlbum != null && _cachedAlbumLocale == code) {
      return _cachedAlbum!;
    }
    try {
      final t = await AppLocalizations.delegate.load(Locale(code));
      _cachedAlbum = t.mediaAlbum;
      _cachedAlbumLocale = code;
      return t.mediaAlbum;
    } catch (_) {
      // Fallback: hardcoded English title if the ARB delegate is
      // somehow unavailable. Should never happen in practice but
      // keeps the handler robust against test harness quirks.
      return 'Quran';
    }
  }

  Future<void> _broadcast(AudioPlayerState s) async {
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
        album: await _album(),
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

  /// Отменить подписку на поток контроллера. Вызывается явно из
  /// тестов / tearDown; в проде handler живёт весь app-сеанс и
  /// отписка не нужна (сборщик мусора сам закроет оба Subject'а
  /// внутри BaseAudioHandler).
  Future<void> shutdown() async {
    await _stateSub?.cancel();
    _stateSub = null;
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
