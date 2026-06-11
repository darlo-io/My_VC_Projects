import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/surah_dao.dart';
import '../../../core/i18n/localized_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/ornaments.dart';
import '../../../shared/widgets/screen_header.dart';
import '../data/audio_player_controller.dart';

class ListenScreen extends ConsumerStatefulWidget {
  const ListenScreen({super.key});

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen> {
  String? _reciterId;
  int? _surahId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final recitersAsync = ref.watch(recitersStreamProvider);
    final playerState = ref.watch(audioPlayerControllerProvider);
    final surahDao = ref.watch(surahDaoProvider);

    // Auto-select defaults: first reciter, first surah.
    ref.listen<AsyncValue<List<Reciter>>>(recitersStreamProvider, (prev, next) {
      next.whenData((list) {
        if (_reciterId == null && list.isNotEmpty) {
          _reciterId = ref.read(appPreferencesProvider).reciterId;
          if (list.every((r) => r.id != _reciterId)) {
            _reciterId = list.first.id;
          }
        }
      });
    });
    ref.listen<AudioPlayerState>(audioPlayerControllerProvider, (prev, next) {
      // Пишем в SharedPreferences только при реальной смене чтеца,
      // а не на каждый position-tick (~60 раз/сек).
      if (next.reciter != null && prev?.reciter?.id != next.reciter!.id) {
        ref.read(appPreferencesProvider).setReciterId(next.reciter!.id);
      }
      // Показываем SnackBar при переходе из `loading -> error` или
      // при первой установке `error` после успешной сессии. Раньше
      // ошибка плеера была невидима в UI (CRITICAL из code review).
      if (next.error != null && prev?.error != next.error) {
        // Отложенно, чтобы SnackBar не конфликтовал с текущим
        // showModalBottomSheet (если он открыт) и не плодил
        // дубликаты при быстрых сменах состояния.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.playerError),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        });
      }
    });

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: t.navListen,
            onBack: () => context.go('/'),
            actions: [
              CircleIconButton(
                icon: Icons.settings_outlined,
                onTap: () => context.go('/profile'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: recitersAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (reciters) {
                if (reciters.isEmpty) {
                  return Center(
                    child: Text(
                      t.searchResultsEmpty,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return _ListenBody(
                  reciters: reciters,
                  playerState: playerState,
                  selectedReciterId: _reciterId,
                  selectedSurahId: _surahId,
                  onReciterChanged: (id) => setState(() => _reciterId = id),
                  onSurahChanged: (id) => setState(() => _surahId = id),
                  onPlay: () {
                    final r = _reciterId ?? reciters.first.id;
                    final s = _surahId ?? 1;
                    ref
                        .read(audioPlayerControllerProvider.notifier)
                        .playSurah(reciterId: r, surahId: s);
                  },
                  onTogglePause: () => ref
                      .read(audioPlayerControllerProvider.notifier)
                      .togglePlay(),
                  surahDao: surahDao,
                  onSpeed: (s) => ref
                      .read(audioPlayerControllerProvider.notifier)
                      .setSpeed(s),
                  onSleepTimer: (m) => ref
                      .read(audioPlayerControllerProvider.notifier)
                      .setSleepTimer(m),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ListenBody extends StatelessWidget {
  const _ListenBody({
    required this.reciters,
    required this.playerState,
    required this.selectedReciterId,
    required this.selectedSurahId,
    required this.onReciterChanged,
    required this.onSurahChanged,
    required this.onPlay,
    required this.onTogglePause,
    required this.surahDao,
    required this.onSpeed,
    required this.onSleepTimer,
  });

  final List<Reciter> reciters;
  final AudioPlayerState playerState;
  final String? selectedReciterId;
  final int? selectedSurahId;
  final ValueChanged<String> onReciterChanged;
  final ValueChanged<int> onSurahChanged;
  final VoidCallback onPlay;
  final VoidCallback onTogglePause;
  final SurahDao surahDao;
  final ValueChanged<double> onSpeed;
  final ValueChanged<int?> onSleepTimer;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _ReciterCarousel(
          reciters: reciters,
          selectedId: selectedReciterId,
          onChanged: onReciterChanged,
        ),
        const SizedBox(height: 28),
        _Player(
          state: playerState,
          onPlay: onPlay,
          onTogglePause: onTogglePause,
        ),
        const SizedBox(height: 16),
        // Playback controls: speed, sleep timer, night mode.
        // Отдельный widget чтобы build() `_Player` остался
        // компактным.
        _PlaybackControls(
          state: playerState,
          onSpeed: onSpeed,
          onSleepTimer: onSleepTimer,
        ),
        const SizedBox(height: 28),
        _SurahPicker(
          surahDao: surahDao,
          selectedId: selectedSurahId,
          onChanged: onSurahChanged,
        ),
        const SizedBox(height: 16),
        Text(
          playerState.surah == null
              ? t.selectSurahAndPlay
              : '${t.nowPlaying}: ${playerState.surahName} • '
                  '${playerState.reciter == null ? '' : t.reciterName(playerState.reciter!.id, fallback: playerState.reciter!.nameEn)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Панель управления воспроизведением: скорость, sleep timer,
/// night mode. Появляется сразу под основной «круглой» play-кнопкой
/// и иконкой состояния (PLAYING / PAUSED).
class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.state,
    required this.onSpeed,
    required this.onSleepTimer,
  });

  final AudioPlayerState state;
  final ValueChanged<double> onSpeed;
  final ValueChanged<int?> onSleepTimer;

  static const _kSpeedOptions = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  static const _kSleepOptions = <int?>[null, 5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status line (PLAYING / PAUSED) + Night mode toggle
          Row(
            children: [
              // Pulse dot — animated "now playing" indicator
              _PlayingDot(active: state.playing),
              const SizedBox(width: 8),
              Text(
                state.playing ? t.audioPlaying : t.audioPaused,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: t.audioNightMode,
                onPressed: () {
                  // night mode — placeholder. В будущем — понижение
                  // громкости до 50% и смена эквалайзера.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.audioNightMode),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.bedtime_outlined,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Speed + Sleep timer (chips)
          Row(
            children: [
              Expanded(
                child: _ControlRow(
                  icon: Icons.speed,
                  label: t.audioSpeed,
                  value: _formatSpeed(state.speed, t),
                  options: _kSpeedOptions
                      .map((s) => _formatSpeed(s, t))
                      .toList(),
                  optionValues: _kSpeedOptions.cast<Object>(),
                  currentValue: state.speed,
                  onChanged: (v) => onSpeed(v as double),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ControlRow(
                  icon: Icons.bedtime,
                  label: t.audioSleepTimer,
                  value: _formatSleep(state.sleepTimerAtMs, t),
                  options: _kSleepOptions
                      .map((m) => _formatSleepMinutes(m, t))
                      .toList(),
                  optionValues: _kSleepOptions.cast<Object>(),
                  currentValue: state.sleepTimerAtMs,
                  onChanged: (v) => onSleepTimer(v as int?),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSpeed(double s, AppLocalizations t) {
    if ((s - 1.0).abs() < 0.01) return t.audioSpeedOff;
    return '${s.toStringAsFixed(s.truncateToDouble() == s ? 0 : 2)}x';
  }

  String _formatSleep(DateTime? at, AppLocalizations t) {
    if (at == null) return t.audioSleepOff;
    final remaining = at.difference(DateTime.now());
    if (remaining.isNegative || remaining == Duration.zero) {
      return t.audioSleepOff;
    }
    final mins = remaining.inMinutes;
    if (mins >= 1) {
      return t.audioSleepMinutes(mins);
    }
    return t.audioSleepMinutes(1);
  }

  String _formatSleepMinutes(int? m, AppLocalizations t) {
    if (m == null) return t.audioSleepOff;
    return t.audioSleepMinutes(m);
  }
}

/// Одна строка «icon + label + value» с tap-to-cycle / tap-to-open
/// chip. Не bottom sheet, а **меню в стиле popup menu** — короткий
/// список значений (3-7), выбираемый напрямую.
class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.optionValues,
    required this.currentValue,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final List<Object?> optionValues;
  final Object? currentValue;
  final ValueChanged<Object> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final picked = await showModalBottomSheet<Object>(
            context: context,
            backgroundColor: AppColors.surface,
            builder: (sheetCtx) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.borderSubtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      for (var i = 0; i < options.length; i++)
                        ListTile(
                          leading: Icon(
                            icon,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          title: Text(
                            options[i],
                            style: TextStyle(
                              color: optionValues[i] == currentValue
                                  ? AppColors.gold
                                  : AppColors.textPrimary,
                              fontWeight: optionValues[i] == currentValue
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: optionValues[i] == currentValue
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.gold,
                                  size: 18,
                                )
                              : null,
                          onTap: () => Navigator.of(sheetCtx).pop(
                            optionValues[i],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
          if (picked != null) onChanged(picked);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Маленькая пульсирующая точка-индикатор «сейчас играет». Анимация —
/// `AnimatedOpacity` (0.4 ↔ 1.0), 1 секунда, infinite. В MVP v0.2
/// без анимации хватает `AnimatedContainer` с opacity.
class _PlayingDot extends StatefulWidget {
  const _PlayingDot({required this.active});
  final bool active;

  @override
  State<_PlayingDot> createState() => _PlayingDotState();
}

class _PlayingDotState extends State<_PlayingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PlayingDot old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final opacity = widget.active ? 0.4 + 0.6 * _ctrl.value : 0.3;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.active
                ? AppColors.gold.withValues(alpha: opacity)
                : AppColors.textTertiary.withValues(alpha: opacity),
            boxShadow: widget.active
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: opacity * 0.6),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}

class _ReciterCarousel extends StatelessWidget {
  const _ReciterCarousel({
    required this.reciters,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Reciter> reciters;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: reciters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final r = reciters[i];
          final selected = r.id == selectedId;
          return _ReciterChip(
            reciter: r,
            selected: selected,
            onTap: () => onChanged(r.id),
          );
        },
      ),
    );
  }
}

class _ReciterChip extends StatelessWidget {
  const _ReciterChip({
    required this.reciter,
    required this.selected,
    required this.onTap,
  });

  final Reciter reciter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 110,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.surfaceElevated
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.borderSubtle,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GoldIconBadge(
                icon: Icons.mic_none,
                size: 44,
                iconSize: 22,
                background: Colors.transparent,
              ),
              const SizedBox(height: 8),
              Text(
                t.reciterName(reciter.id, fallback: reciter.nameEn),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.gold
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Player extends ConsumerWidget {
  const _Player({
    required this.state,
    required this.onPlay,
    required this.onTogglePause,
  });

  final AudioPlayerState state;
  final VoidCallback onPlay;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final hasTrack = state.surah != null;
    final playing = state.playing;
    final pos = state.positionMs;
    final dur = state.durationMs > 0 ? state.durationMs : 1;
    final error = state.error;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: hasTrack ? onTogglePause : onPlay,
                child: Center(
                  child: state.loading
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.textOnGold,
                            ),
                          ),
                        )
                      : Icon(
                          hasTrack
                              ? (playing ? Icons.pause : Icons.play_arrow)
                              : Icons.play_arrow,
                          color: AppColors.textOnGold,
                          size: 48,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            state.surah == null
                ? '—'
                : t.surahName(state.surah!.id, fallback: state.surah!.nameTransliteration),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.reciter == null
                ? ''
                : t.reciterName(state.reciter!.id, fallback: state.reciter!.nameEn),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          // Error-баннер: показывается когда `state.error` непуст.
          // До Tier 2 это было CRITICAL — UI молчал при сбое
          // загрузки и пользователь видел зависший спиннер.
          if (error != null) ...[
            const SizedBox(height: 16),
            _PlayerErrorBanner(
              message: t.playerError,
              hint: t.playerErrorHelp,
              onRetry: () {
                // Очищаем ошибку и заново зовём playSurah. Стейт
                // контроллера поддерживает copyWith(clearError: true).
                final ctrl = ref.read(audioPlayerControllerProvider.notifier);
                ctrl.clearError();
                onPlay();
              },
            ),
          ],
          const SizedBox(height: 16),
          Slider(
            value: hasTrack ? (pos / dur).clamp(0.0, 1.0) : 0.0,
            onChanged: hasTrack
                ? (v) {
                    final target = Duration(
                      milliseconds: (v * dur).round(),
                    );
                    ref
                        .read(audioPlayerControllerProvider.notifier)
                        .seekTo(target);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

/// Баннер с сообщением об ошибке плеера и кнопкой retry.
class _PlayerErrorBanner extends StatelessWidget {
  const _PlayerErrorBanner({
    required this.message,
    required this.hint,
    required this.onRetry,
  });
  final String message;
  final String hint;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Icon(Icons.refresh, size: 18),
          ),
        ],
      ),
    );
  }
}

class _SurahPicker extends ConsumerStatefulWidget {
  const _SurahPicker({
    required this.surahDao,
    required this.selectedId,
    required this.onChanged,
  });

  final SurahDao surahDao;
  final int? selectedId;
  final ValueChanged<int> onChanged;

  @override
  ConsumerState<_SurahPicker> createState() => _SurahPickerState();
}

class _SurahPickerState extends ConsumerState<_SurahPicker> {
  List<Surah>? _all;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.surahDao.getAll();
    if (!mounted) return;
    setState(() {
      _all = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_loading || _all == null) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final selected = widget.selectedId ?? _all!.first.id;
    return Row(
      children: [
        const Icon(Icons.menu_book, color: AppColors.gold, size: 22),
        const SizedBox(width: 12),
        Text(
          '${t.surahLabel}:',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          // DropdownButton requires a Material ancestor. Wrap in
          // transparent Material so it works outside GlassCard's own
          // Material wrapper (e.g. inside a ListView/Row chain).
          child: Material(
            color: Colors.transparent,
            child: DropdownButton<int>(
              value: selected,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              underline: const SizedBox.shrink(),
              iconEnabledColor: AppColors.gold,
              items: _all!
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        '${s.id}. ${t.surahName(s.id, fallback: s.nameTransliteration)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) widget.onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
