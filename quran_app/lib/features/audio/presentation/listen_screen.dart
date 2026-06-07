import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/surah_dao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/ornaments.dart';
import '../../../shared/widgets/screen_header.dart';
import '../data/audio_player_controller.dart';
import '../data/reciters_repository.dart';

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

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 28),
        _SurahPicker(
          surahDao: surahDao,
          selectedId: selectedSurahId,
          onChanged: onSurahChanged,
        ),
        const SizedBox(height: 16),
        Text(
          playerState.surah == null
              ? 'Выберите суру и нажмите play'
              : 'Идёт: ${playerState.surahName} • ${playerState.reciter?.nameEn ?? ''}',
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
              GoldIconBadge(
                icon: Icons.mic_none,
                size: 44,
                iconSize: 22,
                background: Colors.transparent,
              ),
              const SizedBox(height: 8),
              Text(
                reciter.nameEn,
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
    final hasTrack = state.surah != null;
    final playing = state.playing;
    final pos = state.positionMs;
    final dur = state.durationMs > 0 ? state.durationMs : 1;

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
            state.surah?.nameTransliteration ?? '—',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.reciter?.nameEn ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
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
        const Text(
          'Сура:',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
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
                      '${s.id}. ${s.nameTransliteration}',
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
      ],
    );
  }
}
