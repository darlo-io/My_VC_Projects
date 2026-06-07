import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/surah_dao.dart';
import 'audio_cache.dart';
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
  });

  final Reciter? reciter;
  final Surah? surah;
  final String surahName;
  final bool playing;
  final bool loading;
  final int positionMs;
  final int durationMs;

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
    bool resetSurah = false,
  }) {
    return AudioPlayerState(
      reciter: reciter ?? this.reciter,
      surah: resetSurah ? null : (surah ?? this.surah),
      surahName: resetSurah ? '' : (surahName ?? this.surahName),
      playing: playing ?? this.playing,
      loading: loading ?? this.loading,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
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
    required AudioCache cache,
    required RecitersRepository reciters,
    required SurahDao surahDao,
  })  : _cache = cache,
        _reciters = reciters,
        _surahDao = surahDao,
        super(AudioPlayerState.empty) {
    _wireStreams();
  }

  final AudioCache _cache;
  final RecitersRepository _reciters;
  final SurahDao _surahDao;

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;

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

  /// Загрузить и проиграть суру.
  Future<void> playSurah({required String reciterId, required int surahId}) async {
    final reciter = await _reciters.getById(reciterId);
    if (reciter == null) return;
    final surah = await _surahDao.getById(surahId);
    if (surah == null) return;

    state = state.copyWith(
      reciter: reciter,
      surah: surah,
      surahName: surah.nameTransliteration,
      loading: true,
    );

    final url = _resolveUrl(reciter, surahId);
    final file = await _cache.getOrDownload(
      reciterId: reciterId,
      surah: surahId,
      url: url,
    );
    await _player.setFilePath(file.path);
    await _player.play();
  }

  Future<void> togglePlay() async {
    if (state.surah == null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seekTo(Duration position) => _player.seek(position);

  Future<void> stop() async {
    await _player.stop();
    state = AudioPlayerState.empty;
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
