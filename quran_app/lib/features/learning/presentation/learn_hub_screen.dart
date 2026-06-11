import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/data/learning_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/progress_ring.dart';

/// Learn hub dashboard — главная "точка входа" в Learn-секцию.
/// Layout (соответствует `docs/images/Learn.png`):
///  1. Header: «Учить» + подзаголовок
///  2. Hero card «Заучивание» с progress-bar (X% mastered) +
///     кнопка «Продолжить» / «Начать»
///  3. Quick access: 4 иконки (Recent / Bookmarks / Stats / Plan)
///  4. Learn by section: list с иконками (Juz' / Surahs / Recent
///     ayahs / Duas / Tajweed)
///  5. Daily goal: X/Y аятов + streak в днях
///
/// Review session (по SM-2) — отдельный экран `/learn/review`,
/// который открывается из карточки «Заучивание» / «Daily goal».
class LearnHubScreen extends ConsumerWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    // Mem stats: кол-во mastered слов (status='mastered')
    // и total слов в словаре.
    final repo = ref.watch(learningRepositoryProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1) Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.learnHubTitle,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.1,
                            fontFamily: 'CormorantGaramond',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.learnHubSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 1.2),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 2) Hero card «Заучивание» с progress-ring и кнопкой
              _MemorizationHeroCard(repo: repo),
              const SizedBox(height: 20),
              // 3) Quick access
              Text(
                t.learnHubQuickAccess,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _QuickAccessIcon(
                    icon: Icons.menu_book,
                    label: t.learnHubRecent,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _QuickAccessIcon(
                    icon: Icons.bookmark_outline,
                    label: t.learnHubMyBookmarks,
                    onTap: () => context.go('/bookmarks'),
                  ),
                  const SizedBox(width: 8),
                  _QuickAccessIcon(
                    icon: Icons.bar_chart,
                    label: t.learnHubMyStats,
                    onTap: () => context.go('/statistics'),
                  ),
                  const SizedBox(width: 8),
                  _QuickAccessIcon(
                    icon: Icons.event_note,
                    label: t.learnHubMyPlan,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 4) Learn by section
              Text(
                t.learnHubBySection,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 8),
              _SectionTile(
                icon: Icons.menu_book,
                title: t.learnHubByJuz,
                subtitle: t.learnHubByJuzHint,
                onTap: () => context.go('/read'),
              ),
              _SectionTile(
                icon: Icons.layers,
                title: t.learnHubBySurah,
                subtitle: t.learnHubBySurahHint,
                onTap: () => context.go('/read'),
              ),
              _SectionTile(
                icon: Icons.history,
                title: t.learnHubRecentAyahs,
                subtitle: t.learnHubRecentAyahsHint,
                onTap: () {},
              ),
              _SectionTile(
                icon: Icons.brightness_5,
                title: t.learnHubDuas,
                subtitle: t.learnHubDuasHint,
                onTap: () {},
              ),
              _SectionTile(
                icon: Icons.record_voice_over,
                title: t.learnHubTajweed,
                subtitle: t.learnHubTajweedHint,
                onTap: () {},
              ),
              const SizedBox(height: 20),
              // 5) Daily goal
              _DailyGoalCard(repo: repo),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero-карточка «Заучивание» с круговым progress-ring, процентом
/// освоенных слов и кнопкой «Продолжить» / «Начать».
class _MemorizationHeroCard extends ConsumerWidget {
  const _MemorizationHeroCard({required this.repo});

  final LearningRepository repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          // Progress ring (аяты / цели за сегодня — 10 аятов)
          StreamBuilder<int>(
            stream: ref.watch(positionDaoProvider).watchAyahsInRange(
                  DateTime.now().subtract(const Duration(hours: 12)),
                  DateTime.now(),
                ),
            builder: (context, snap) {
              final read = snap.data ?? 0;
              final target = 10;
              final pct = (read * 100 / target).clamp(0, 100).toInt();
              return ProgressRing(
                progress: pct / 100,
                value: '$pct',
                suffix: '%',
                size: 100,
                strokeWidth: 8,
                color: AppColors.gold,
                subtitle: t.learnHubMemorizationProgress,
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.learnHubMemorization,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.learnHubMemorizationHint,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/learn/review'),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8C77A), Color(0xFFB5862C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.learnHubContinue,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnGold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: AppColors.textOnGold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Один tile в секции «Быстрый доступ» — иконка + 2-line label.
class _QuickAccessIcon extends StatelessWidget {
  const _QuickAccessIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(icon, color: AppColors.gold, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tile в секции «Учить по разделам»: иконка + title + subtitle.
class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(icon, color: AppColors.gold, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Карточка «Ежедневная цель» — X/Y аятов + серия.
class _DailyGoalCard extends ConsumerWidget {
  const _DailyGoalCard({required this.repo});
  final LearningRepository repo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    const target = 10;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF5C4326),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.gold,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    StreamBuilder<int>(
                      stream: ref.watch(positionDaoProvider).watchAyahsInRange(
                            DateTime.now().subtract(const Duration(hours: 12)),
                            DateTime.now(),
                          ),
                      builder: (context, snap) {
                        final current = snap.data ?? 0;
                        return RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                            children: [
                              TextSpan(text: '$current'),
                              TextSpan(
                                text: ' / $target ${t.statsPerDay.split(' ').last}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  t.learnHubDailyGoalHint,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                // Progress bar (X / target)
                StreamBuilder<int>(
                  stream: ref.watch(positionDaoProvider).watchAyahsInRange(
                        DateTime.now().subtract(const Duration(hours: 12)),
                        DateTime.now(),
                      ),
                  builder: (context, snap) {
                    final current = (snap.data ?? 0).clamp(0, target);
                    final pct = current / target;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceHigh,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.gold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Streak
          StreamBuilder<int>(
            stream: ref.watch(positionDaoProvider).watchStreakDays(),
            builder: (context, snap) {
              final days = snap.data ?? 0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: AppColors.gold,
                    size: 24,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$days',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    t.statsDaysUnit,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
