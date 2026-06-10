import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/learning_dao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Экран Learn — повторение слов по алгоритму SM-2.
///
/// Источник истины: [LearningDao.watchDue]. Список обновляется реактивно:
/// после `recordReview` карточка автоматически сдвигается на следующее due
/// слово (или на экран "Все выучено", если due-список пуст).
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  int _reviewedThisSession = 0;
  // Кэшируем снимок due-списка на момент ревью, чтобы не было глитча
  // (стрим может выдать новое состояние пока мы анимируем переход).
  List<ReviewedWord>? _lastDue;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dueStream = ref.watch(learningRepositoryProvider).watchDue();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          t.learnTitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.gold),
      ),
      body: StreamBuilder<List<ReviewedWord>>(
        stream: dueStream,
        builder: (context, snapshot) {
          final due = snapshot.data ?? _lastDue ?? const <ReviewedWord>[];
          _lastDue = due;

          if (due.isEmpty) {
            return const _EmptyState();
          }

          final current = due.first;
          return _ReviewView(
            word: current.word,
            entry: current.entry,
            dueCount: due.length,
            reviewedThisSession: _reviewedThisSession,
            onReview: (quality) => _handleReview(current, quality),
            onSkip: () => setState(() => _reviewedThisSession++),
          );
        },
      ),
    );
  }

  Future<void> _handleReview(ReviewedWord rw, int quality) async {
    await ref
        .read(learningRepositoryProvider)
        .recordReview(wordId: rw.word.id, quality: quality);
    if (!mounted) return;
    setState(() => _reviewedThisSession++);
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({
    required this.word,
    required this.entry,
    required this.dueCount,
    required this.reviewedThisSession,
    required this.onReview,
    required this.onSkip,
  });

  final Word word;
  final LearningWord entry;
  final int dueCount;
  final int reviewedThisSession;
  final void Function(int quality) onReview;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        children: [
          _ProgressHeader(
            total: dueCount,
            reviewed: reviewedThisSession,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _WordCard(word: word, entry: entry),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _QualityGrid(onReview: onReview),
          ),
          TextButton(
            onPressed: onSkip,
            child: Text(
              t.learnSkip,
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.total, required this.reviewed});

  final int total;
  final int reviewed;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final left = (total - reviewed).clamp(0, total);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.learnRemaining(left),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                t.learnSession(reviewed),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : reviewed / total,
              minHeight: 4,
              backgroundColor: AppColors.surfaceHigh,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  const _WordCard({required this.word, required this.entry});

  final Word word;
  final LearningWord entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            word.arabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 72,
              fontWeight: FontWeight.w700,
              color: AppColors.gold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            word.normalized,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          if (word.translation != null && word.translation!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 20),
            Text(
              word.translation!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _StatusPill(status: entry.status),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final color = switch (status) {
      'mastered' => AppColors.success,
      'reviewing' => AppColors.gold,
      'learning' => AppColors.warning,
      _ => AppColors.textTertiary,
    };
    final label = switch (status) {
      'mastered' => t.learnStatusMastered,
      'reviewing' => t.learnStatusReviewing,
      'learning' => t.learnStatusLearning,
      _ => t.learnStatusNew,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Шесть кнопок SM-2 quality, разбитых на «плохо» (0..2) и «хорошо» (3..5).
class _QualityGrid extends StatelessWidget {
  const _QualityGrid({required this.onReview});

  final void Function(int quality) onReview;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QualityButton(
                quality: 0,
                label: t.learnQuality0,
                color: AppColors.error,
                onTap: onReview,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QualityButton(
                quality: 1,
                label: t.learnQuality1,
                color: AppColors.error,
                onTap: onReview,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QualityButton(
                quality: 2,
                label: t.learnQuality2,
                color: AppColors.warning,
                onTap: onReview,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _QualityButton(
                quality: 3,
                label: t.learnQuality3,
                color: AppColors.gold,
                onTap: onReview,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QualityButton(
                quality: 4,
                label: t.learnQuality4,
                color: AppColors.success,
                onTap: onReview,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QualityButton(
                quality: 5,
                label: t.learnQuality5,
                color: AppColors.success,
                onTap: onReview,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QualityButton extends StatelessWidget {
  const _QualityButton({
    required this.quality,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final int quality;
  final String label;
  final Color color;
  final void Function(int quality) onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTap(quality),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                '$quality',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              t.learnEmptyTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.learnEmptyHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
