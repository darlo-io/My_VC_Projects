import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/i18n/localized_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/ornaments.dart';

/// Компактный плеер поверх экрана, когда идёт воспроизведение.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final state = ref.watch(audioPlayerControllerProvider);
    if (state.surah == null) return const SizedBox.shrink();

    // Если плеер в error-состоянии, показываем вместо плей/паузы
    // иконку ошибки с подсветкой — пользователь сразу видит, что
    // нужно тапнуть и retry.
    final hasError = state.error != null;

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
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.gold,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasError ? AppColors.error : AppColors.gold)
                      .withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                GoldIconBadge(
                  icon: hasError
                      ? Icons.error_outline
                      : (state.playing ? Icons.graphic_eq : Icons.music_note),
                  size: 40,
                  iconSize: 20,
                  background: Colors.transparent,
                  borderColor: hasError ? AppColors.error : AppColors.gold,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.surahName(state.surah!.id, fallback: state.surahName),
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
                        hasError
                            ? t.playerError
                            : (state.reciter == null
                                ? ''
                                : t.reciterName(
                                    state.reciter!.id,
                                    fallback: state.reciter!.nameEn,
                                  )),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasError
                              ? AppColors.error
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (hasError) {
                      // Retry: чистим ошибку и зовём playSurah заново
                      // через контроллер.
                      ref
                          .read(audioPlayerControllerProvider.notifier)
                          .clearError();
                      if (state.reciter != null) {
                        ref
                            .read(audioPlayerControllerProvider.notifier)
                            .playSurah(
                              reciterId: state.reciter!.id,
                              surahId: state.surah!.id,
                            );
                      }
                    } else {
                      ref.read(quranAudioHandlerProvider).play();
                    }
                  },
                  icon: Icon(
                    hasError ? Icons.refresh : (state.playing ? Icons.pause : Icons.play_arrow),
                    color: hasError ? AppColors.error : AppColors.gold,
                  ),
                ),
                IconButton(
                  onPressed: () => ref
                      .read(quranAudioHandlerProvider)
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
