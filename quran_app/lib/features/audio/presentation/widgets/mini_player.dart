import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ornaments.dart';

/// Компактный плеер поверх экрана, когда идёт воспроизведение.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlayerControllerProvider);
    if (state.surah == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/listen'),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.surfaceElevated, AppColors.surface],
              ),
              border: Border.all(color: AppColors.gold, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                GoldIconBadge(
                  icon: state.playing ? Icons.graphic_eq : Icons.music_note,
                  size: 40,
                  iconSize: 20,
                  background: Colors.transparent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.surahName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.reciter?.nameEn ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(audioPlayerControllerProvider.notifier)
                      .togglePlay(),
                  icon: Icon(
                    state.playing ? Icons.pause : Icons.play_arrow,
                    color: AppColors.gold,
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(audioPlayerControllerProvider.notifier)
                      .stop(),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
