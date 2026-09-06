import 'dart:async';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `AudioSource` в just_audio конфликтует с нашим `AudioSource` в
// audio_source_chain.dart, поэтому скрываем just_audio-версию и
// используем [UriAudioSource]/[ConcatenatingAudioSource] напрямую.
import 'package:just_audio/just_audio.dart' hide AudioSource;

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/playback_sessions_dao.dart';
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
    this.currentAyah,
    this.totalAyahs,
    this.error,
    this.speed = 1.0,
    this.sleepTimerAtMs,
    this.nightMode = false,
  });

  final Reciter? reciter;
  final Surah? surah;
  final String surahName;
  final bool playing;
  final bool loading;
  final int positionMs;
  final int durationMs;

  /// Номер текущего аята (1..totalAyahs). Обновляется из
  /// `positionStream` в [AudioPlayerController]. null если сура не
  /// загружена. Оценка по `positionMs / durationMs * totalAyahs`,
  /// clamp в [1, totalAyahs]. Для точной подсветки нужен mp3quran
  /// `/ayat_timing` (Phase 3), см. AGENTS.md.
  final int? currentAyah;

  /// Всего аятов в текущей суре. Из [Surah.ayahCount]. null если
  /// сура не загружена.
  final int? totalAyahs;

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

  /// Night mode: `true` → приглушённая громкость
  /// (`AudioPlayerController.kNightModeVolume`, default 0.4) для
  /// ночного прослушивания / в наушниках. `false` → полная
  /// громкость 1.0. См. [AudioPlayerController.setNightMode].
  final bool nightMode;

  static const empty = AudioPlayerState(
    reciter: null,
    surah: null,
    surahName: '',
    playing: false,
    loading: false,
    positionMs: 0,
    durationMs: 0,
  );

  /// Значимое равенство: `StateNotifier` не уведомляет подписчиков,
  /// если новая state равна старой. Без этого каждый тик
  /// `positionStream` (~20/с) пересобирал ВСЕ виджеты, вотчащие
  /// `audioPlayerControllerProvider` (ListenScreen, MiniPlayer,
  /// все аяты открытого Reader'а). В паре с квантованием
  /// `positionMs` до секунд в контроллере даёт ≤1 нотификацию/с.
  @override
  bool operator ==(Object other) =>
      other is AudioPlayerState &&
      other.reciter == reciter &&
      other.surah == surah &&
      other.surahName == surahName &&
      other.playing == playing &&
      other.loading == loading &&
      other.positionMs == positionMs &&
      other.durationMs == durationMs &&
      other.currentAyah == currentAyah &&
      other.totalAyahs == totalAyahs &&
      other.error == error &&
      other.speed == speed &&
      other.sleepTimerAtMs == sleepTimerAtMs &&
      other.nightMode == nightMode;

  @override
  int get hashCode => Object.hash(
        reciter,
        surah,
        surahName,
        playing,
        loading,
        positionMs,
        durationMs,
        currentAyah,
        totalAyahs,
        error,
        speed,
        sleepTimerAtMs,
        nightMode,
      );

  AudioPlayerState copyWith({
    Reciter? reciter,
    Surah? surah,
    String? surahName,
    bool? playing,
    bool? loading,
    int? positionMs,
    int? durationMs,
    int? currentAyah,
    int? totalAyahs,
    String? error,
    bool clearError = false,
    double? speed,
    DateTime? sleepTimerAtMs,
    bool clearSleepTimer = false,
    bool? nightMode,
  }) {
    return AudioPlayerState(
      reciter: reciter ?? this.reciter,
      surah: surah ?? this.surah,
      surahName: surahName ?? this.surahName,
      playing: playing ?? this.playing,
      loading: loading ?? this.loading,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      currentAyah: currentAyah ?? this.currentAyah,
      totalAyahs: totalAyahs ?? this.totalAyahs,
      error: clearError ? null : (error ?? this.error),
      speed: speed ?? this.speed,
      sleepTimerAtMs:
          clearSleepTimer ? null : (sleepTimerAtMs ?? this.sleepTimerAtMs),
      nightMode: nightMode ?? this.nightMode,
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
/// - Телеметрия сессий прослушивания в `playback_sessions`
///   (master-plan §4.4)
class AudioPlayerController extends StateNotifier<AudioPlayerState> {
  AudioPlayerController({
    required this._cache,
    required this._reciters,
    required this._surahDao,
    required this._sessions,
  })  : super(AudioPlayerState.empty) {
    _wireStreams();
  }

  final AudioCache _cache;
  final RecitersRepository _reciters;
  final SurahDao _surahDao;
  final PlaybackSessionsDao _sessions;

  /// ID текущей открытой сессии (для [playback_sessions]). `null`
  /// пока ни одна не открыта. На каждый `playSurah` открываем
  /// новую строку и закрываем её на `stop` / смене суры / длинной
  /// паузе (срабатывает через таймер ниже).
  int? _activeSessionId;
  String? _activeSessionReciterId;
  int? _activeSessionSurahId;
  Duration _activePlayedDuration = Duration.zero;
  DateTime? _activeLastResumeAt;
  Timer? _inactivityTimer;

  static const _inactivityTimeout = Duration(minutes: 10);

  /// Вспомогательный clamp для [Duration]. `dart:core` не предоставляет
  /// `Duration.clamp` в стабильных SDK, с которыми собирается этот
  /// проект; реализуем минимально нужный вариант сами.
  ///
  /// Защищаем `totalMs` от катастрофических значений:
  ///   - отрицательная дельта (часы на устройстве перевели назад);
  ///   - дельта > 6 часов (устройство «уснуло» с открытым плеером
  ///     и проснулось только сейчас — это не реальное прослушивание).
  static Duration _clampDuration(Duration d) {
    const max = Duration(hours: 6);
    if (d.isNegative) return Duration.zero;
    if (d > max) return max;
    return d;
  }

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration?>? _durSub;
  Timer? _sleepTimer;

  /// Дефолт `StateNotifier.updateShouldNotify` — `!identical(old,
  /// current)`: без этого переопределения каждый `copyWith` (новый
  /// инстанс) уведомлял бы всех подписчиков даже при равных значениях.
  /// Со значимым `operator==` у [AudioPlayerState] нотификации идут
  /// только при реальном изменении состояния (с квантованием позиции
  /// до секунд в `_wireStreams` — ≤1/с во время воспроизведения).
  @override
  bool updateShouldNotify(AudioPlayerState old, AudioPlayerState current) =>
      old != current;

  /// Активный `CancelToken` для download-фазы `getOrDownload`.
  /// Если пользователь жмёт stop / play другую суру до завершения
  /// загрузки — отменяем in-flight запрос, иначе полу-скачанный
  /// файл запишется как «ready» и следующий `play(sameSurah)` отдаст
  /// битый путь. См. master-plan §4.3 «обработка ошибок».
  CancelToken _downloadCancel = CancelToken();

  void _wireStreams() {
    _stateSub = _player.playerStateStream.listen((s) {
      state = state.copyWith(
        playing: s.playing,
        loading: s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering,
      );
    });
    _posSub = _player.positionStream.listen((p) {
      // В state пишем «грубую» позицию, квантованную до секунд.
      // Short-circuit до записи: внутри одной секунды (и без смены
      // аята) не создаём новый инстанс state вообще.
      final coarseMs = p.inMilliseconds ~/ 1000 * 1000;
      if (coarseMs == state.positionMs) {
        // duration обновляется отдельной подпиской; при неизменной
        // секунде currentAyah тоже не меняется.
        return;
      }
      state = state.copyWith(
        positionMs: coarseMs,
        currentAyah: _computeCurrentAyah(coarseMs),
      );
    });
    _durSub = _player.durationStream.listen((d) {
      if (d != null) {
        state = state.copyWith(
          durationMs: d.inMilliseconds,
          currentAyah: _computeCurrentAyah(
            state.positionMs,
            overrideDuration: d.inMilliseconds,
          ),
        );
      }
    });
  }

  /// Точный поток позиции воспроизведения (нативные тики just_audio,
  /// ~20/с). Используется точечно для задач, которым нужна
  /// гранулярность выше секунды (подсветка активного слова в
  /// `currentWordIdProvider`), минуя `StateNotifier` — чтобы каждый
  /// тик не пересобирал все виджеты, вотчащие контроллер.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Возвращает глобальный номер 1-го аята данной суры (т.е. суммарное
  /// число аятов во всех предыдущих сурах + 1). Используется для
  /// per-ayah режима, где CDN ждёт глобальный id аята 1..6236, а не
  /// локальный 1..ayahCount.
  ///
  /// Проиграть суру: качаем per-surah файл и отдаём в just_audio через
  /// `setFilePath`.
  ///
  /// Источники перебираются через [resolveSurahUrlCandidates]:
  /// сначала QuranAudio CDN (quranicaudio.com, если есть маппинг в
  /// `kMp3quranToQuranAudio`), затем mp3quran.net. Перебор нужен
  /// потому что любой CDN может деградировать (mp3quran.net
  /// нестабилен с mid-2026: DNS hijacks, rate limits; Quran.com не
  /// имеет per-surah файлов вовсе): если primary умер, playback
  /// уходит на фоллбэк вместо ошибки. Кеш-ключ `{reciterId}/{surah}`
  /// один и тот же для обоих источников — контент идентичен.
  ///
  /// Используется рекомендованная структура кеша `audio_cache/{id}/
  /// {NNN}.mp3` (см. AGENTS.md «Audio playback — CDN and cache»).
  ///
  /// Cache-first воспроизведение суры:
  ///   1. Файл уже в кеше (валидный) → [AudioPlayer.setFilePath]:
  ///      мгновенный старт, оффлайн, без сетевой буферизации.
  ///   2. Файла нет → [AudioPlayer.setUrl] (стриминг): время до звука
  ///      = буфер, а не весь файл. Параллельно запускаем фоновую
  ///      докачку в кеш ([getOrDownload]) с того же рабочего URL,
  ///      чтобы повторы и оффлайн сработали без повторной полной
  ///      загрузки. Двойная загрузка (стрим + кеш на первом
  ///      прослушивании) — осознанный трейд-офф: мгновенный старт
  ///      против ~2× трафика.
  Future<void> _playSurahMp3Quran({
    required Reciter reciter,
    required Surah surah,
    required CancelToken cancelToken,
  }) async {
    final candidates = resolveSurahUrlCandidates(reciter, surah.id);
    if (candidates.isEmpty) {
      throw StateError(
        'Reciter ${reciter.id} has no mp3quran/quran_com metadata — '
        'run syncFromApi() to populate',
      );
    }
    final reciterId = reciter.id;

    // 1) Cache-hit → локальное воспроизведение (мгновенно, оффлайн).
    //    Ключ кеша не зависит от источника — файл, скачанный с любого
    //    из кандидатов, переиспользуется.
    final cached = await _cache.peekCachedFile(
      reciterId: reciterId,
      surah: surah.id,
    );
    if (cached != null) {
      if (cancelToken.isCancelled) {
        throw StateError('Download cancelled before playback');
      }
      developer.log(
        '_playSurahMp3Quran cache-hit -> ${cached.path}',
        name: 'playback',
      );
      // Ре-чек после await'ов выше: stop/новый playSurah могли
      // случиться, пока мы читали кеш.
      if (cancelToken.isCancelled) {
        throw StateError('Download cancelled before playback');
      }
      await _player.setFilePath(cached.path);
      await _player.play();
      developer.log(
        '_playSurahMp3Quran _player.play() returned (cache)',
        name: 'playback',
      );
      return;
    }

    // 2) Cache-miss → стриминг по сети с перебором кандидатов.
    //    setUrl бросает [PlayerException] при source error (404/5xx/
    //    network) — идём к следующему кандидату. Последняя ошибка —
    //    в исключении, чтобы playSurah показал её в state.error.
    Object? lastError;
    for (final url in candidates) {
      if (cancelToken.isCancelled) {
        throw StateError('Download cancelled before playback');
      }
      developer.log(
        '_playSurahMp3Quran streaming reciter=$reciterId surah=${surah.id} url=$url',
        name: 'playback',
      );
      try {
        await _player.setUrl(url);
      } catch (e) {
        lastError = e;
        developer.log(
          '_playSurahMp3Quran setUrl FAILED ($url): $e — next candidate',
          name: 'playback',
        );
        continue;
      }
      // Ре-чек ПОСЛЕ успешного setUrl: пока load был в полёте, юзер
      // мог нажать stop или запустить другую суру — без этого чека
      // play() стартовал бы аудио вопреки отмене.
      if (cancelToken.isCancelled) {
        throw StateError('Download cancelled before playback');
      }
      // URL рабочий → запускаем фоновую докачку в кеш с него же.
      // Тот же cancelToken, что у play-запроса: stop отменит и её.
      unawaited(
        _cache
            .getOrDownload(
              reciterId: reciterId,
              surah: surah.id,
              url: url,
              cancelToken: cancelToken,
            )
            .then((f) => developer.log(
                  '_playSurahMp3Quran bg-cache OK -> ${f.path}',
                  name: 'playback',
                ))
            .catchError((Object e) => developer.log(
                  '_playSurahMp3Quran bg-cache FAILED: $e',
                  name: 'playback',
                )),
      );
      await _player.play();
      developer.log(
        '_playSurahMp3Quran _player.play() returned (stream)',
        name: 'playback',
      );
      return;
    }
    throw StateError(
      'All audio sources failed for ${reciter.id}/${surah.id}: $lastError',
    );
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
  Future<void> playSurah({
    required String reciterId,
    required int surahId,
    int? startAyah,
  }) async {
    developer.log(
      'playSurah START reciterId=$reciterId surahId=$surahId',
      name: 'playback',
    );
    // Перед каждой новой попыткой проигрывания отменяем прошлый
    // download и заводим свежий `CancelToken`. См. комментарий
    // у `_downloadCancel`.
    if (!_downloadCancel.isCancelled) {
      _downloadCancel.cancel('new-play-request');
    }
    _downloadCancel = CancelToken();
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
        // currentAyah/totalAyahs выставляем сразу (знаем кол-во
        // аятов). currentAyah=1 (старт), а positionStream потом
        // обновит его через _computeCurrentAyah.
        currentAyah: startAyah ?? 1,
        totalAyahs: surah.ayahCount,
      );

      // Воспроизведение через mp3quran.net — per-surah файлы единым
      // блоком (см. AGENTS.md «Audio playback»). Раньше это был
      // per-ayah на cdn.alislam.ru, но per-surah-пути там полностью
      // мертвы (все bitrates 403 на 2026-07), а per-ayah требовал
      // конкатенации 7..286 файлов. На mp3quran.net — один файл
      // и `setFilePath`, без `ConcatenatingAudioSource`.
      developer.log(
        'playSurah reciterId=${reciter.id} surahId=$surahId (mp3quran)',
        name: 'playback',
      );
      await _playSurahMp3Quran(
        reciter: reciter,
        surah: surah,
        cancelToken: _downloadCancel,
      );
      // Если указан startAyah, перематываем к началу этого аята.
      // Приблизительная позиция: (startAyah - 1) / surah.ayahCount.
      if (startAyah != null && surah.ayahCount > 0) {
        final frac = ((startAyah - 1).clamp(0, surah.ayahCount - 1)) /
            surah.ayahCount;
        // Ждём небольшую задержку, чтобы _player успел загрузить файл.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        final dur = state.durationMs;
        if (dur > 0) {
          await _player.seek(Duration(milliseconds: (dur * frac).round()));
        }
      }
      developer.log(
        'playSurah _player.play() returned',
        name: 'playback',
      );

      // Telemetry: открываем сессию прослушивания.
      // Закрывается в `_closeActiveSession` на stop / pause-timeout /
      // dispose. Подробнее — см. master-plan §4.4 + §11.
      await _openSession(
        reciterId: reciter.id,
        surahId: surah.id,
        ayahStart: 1, // currentAyah пока нет в state; для v0.2
                      // фиксируем «слушал с 1-го аята». Phase 3
                      // (подсветка слов) обогатит это до точного id.
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: '$e');
    }
  }

  Future<void> _openSession({
    required String reciterId,
    required int surahId,
    required int ayahStart,
  }) async {
    await _closeActiveSession(closeReason: 'surah_change');
    final id = await _sessions.open(
      reciterId: reciterId,
      surahId: surahId,
      ayahStart: ayahStart,
      startedAt: DateTime.now(),
    );
    _activeSessionId = id;
    _activeSessionReciterId = reciterId;
    _activeSessionSurahId = surahId;
    _activePlayedDuration = Duration.zero;
    _activeLastResumeAt = DateTime.now();
    _resetInactivityTimer();
  }

  /// Вычисляет номер текущего аята (1..totalAyahs) на основе
  /// `positionMs` и `durationMs`. Возвращает `null`, если данных
  /// недостаточно (сура не загружена, длительность 0).
  ///
  /// Для точной подсветки нужен mp3quran `/ayat_timing` API
  /// (см. AGENTS.md «Phase 3»). Сейчас — линейная аппроксимация,
  /// которая даёт ±1 аят на больших сурах (например, Бакара).
  /// Для коротких сур (7-30 аятов) точность достаточная.
  int? _computeCurrentAyah(int positionMs, {int? overrideDuration}) {
    final total = state.surah?.ayahCount ?? state.totalAyahs;
    if (total == null || total <= 0) return null;
    final dur = overrideDuration ?? state.durationMs;
    if (dur <= 0) return state.currentAyah; // нет данных — оставляем старое
    final frac = (positionMs / dur).clamp(0.0, 1.0);
    // 1..total включительно; frac=0 → 1, frac=1 → total.
    final n = (frac * (total - 1)).floor() + 1;
    return n.clamp(1, total);
  }

  Future<void> _closeActiveSession({required String closeReason}) async {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    final id = _activeSessionId;
    if (id == null) return;
    _activeSessionId = null;
    final ended = DateTime.now();
    final lastResume = _activeLastResumeAt;
    final added = lastResume == null
        ? Duration.zero
        : _clampDuration(
            ended.difference(lastResume),
          );
    final totalMs = (_activePlayedDuration + added).inMilliseconds;
    await _sessions.finish(
      id: id,
      // Phase 3 уточнит по WordTimings; на v0.2 пишем тот же
      // `ayahStart` (слушатель ещё не дошёл до конца суры —
      // иначе был бы вызван play следующей и причина закрытия
      // была бы `surah_change`).
      ayahEnd: 1,
      endedAt: ended,
      durationPlayedMs: totalMs,
      closeReason: closeReason,
    );
    _activePlayedDuration = Duration.zero;
    _activeLastResumeAt = null;
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, () {
      // Долгая пауза (без `_posSub` обновлений) → закрываем сессию.
      // Если плеер всё ещё «playing», `_posSub` будет обновлять
      // `positionMs`, и таймер сбрасывается в `togglePlay()` →
      // см. `pause()` ветку ниже.
      unawaited(_closeActiveSession(closeReason: 'pause_timeout'));
    });
  }

  Future<void> togglePlay() async {
    if (state.surah == null) return;
    if (_player.playing) {
      await _player.pause();
      // Закрываем активную сессию на «pause» — пользователь явно
      // остановился; если он сразу нажмёт play — откроем новую.
      // Phase 3 объединит это с привязкой к WordTimings для
      // точного подсчёта аятов.
      final resume = _activeLastResumeAt;
      if (resume != null) {
        _activePlayedDuration +=
            _clampDuration(DateTime.now().difference(resume));
        _activeLastResumeAt = null;
      }
      _inactivityTimer?.cancel();
      await _closeActiveSession(closeReason: 'pause');
    } else {
      await _player.play();
      // Возобновляем сессию (новая строка), чтобы не плодить
      // «дыры» в телеметрии во время длительной паузы.
      final reciter = _activeSessionReciterId;
      final surah = _activeSessionSurahId;
      if (reciter != null && surah != null) {
        await _openSession(
          reciterId: reciter,
          surahId: surah,
          ayahStart: 1,
        );
      }
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

  /// Громкость в night mode (0.0 — тишина, 1.0 — полная).
  /// 0.4 выбрано как «слышно на тихой комнате, не разбудит ребёнка».
  static const double kNightModeVolume = 0.4;

  /// Включить/выключить ночной режим.
  ///
  /// **Реализация (2026-07-17)**: dim громкости через `AudioPlayer.setVolume`.
  /// На MVP v0.2 это единственная доступная runtime-настройка —
  /// переключение битрейта/каналов требует re-encoding источника, что
  /// just_audio не делает на лету. Volume dim — прагматичный минимум,
  /// который реально помогает при ночном прослушивании в наушниках.
  ///
  /// Флаг сохраняется в [AudioPlayerState.nightMode], чтобы UI мог
  /// показать индикатор (иконка луны в `_PlaybackControls`). На
  /// следующем `playSurah` / `play()` громкость не сбрасывается —
  /// пользователь явно выключает night mode.
  Future<void> setNightMode(bool enabled) async {
    state = state.copyWith(nightMode: enabled);
    await _player.setVolume(enabled ? kNightModeVolume : 1.0);
    developer.log(
      'setNightMode(enabled=$enabled) → volume=${enabled ? kNightModeVolume : 1.0}',
      name: 'playback',
    );
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
    // Отменить in-flight download (если пользователь нажал stop
    // посреди загрузки). См. комментарий у `_downloadCancel`.
    if (!_downloadCancel.isCancelled) {
      _downloadCancel.cancel('user-stopped');
    }
    _downloadCancel = CancelToken();
    await _closeActiveSession(closeReason: 'stop');
    await _player.stop();
    state = AudioPlayerState.empty;
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _inactivityTimer?.cancel();
    // Закрываем сессию синхронно (fire-and-forget); dispose() не
    // принимает `Future`, но Drift write через `customInsert`/
    // `update` тоже async — лучше «потерять» последнюю точку чем
    // задерживать dispose.
    unawaited(_closeActiveSession(closeReason: 'app_exit'));
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
