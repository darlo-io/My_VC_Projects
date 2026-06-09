import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/screen_header.dart';
import '../data/quiz_session.dart';

/// 10-question multiple-choice quiz over the user's UI-locale
/// translations of the Quran. Replaces the "Coming soon" stub
/// that the home screen's Test card used to lead to.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  // `null` means the user hasn't answered the current question yet.
  // We keep this state-local rather than on the [QuizSession]
  // because [QuizSession] is immutable and re-creating one per
  // answer is wasteful for a UI-only flag.
  int? _selectedIndex;

  void _restart() {
    setState(() => _selectedIndex = null);
    ref.invalidate(quizSessionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final sessionAsync = ref.watch(quizSessionProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: t.quizTitle,
              onBack: () {
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/');
                }
              },
            ),
            Expanded(
              child: sessionAsync.when(
                loading: () => const _Loading(),
                error: (e, _) => _ErrorState(
                  message: '$e',
                  onRetry: _restart,
                ),
                data: (session) {
                  if (session == null) {
                    return _Empty(message: t.quizEmpty);
                  }
                  if (session.isFinished) {
                    return _ResultsCard(
                      session: session,
                      onPlayAgain: _restart,
                    );
                  }
                  return _QuestionView(
                    session: session,
                    selectedIndex: _selectedIndex,
                    onSelect: (i) => setState(() => _selectedIndex = i),
                    onSkip: () {
                      session.skip();
                      session.next();
                      setState(() => _selectedIndex = null);
                    },
                    onNext: () {
                      session.answer(_selectedIndex);
                      session.next();
                      setState(() => _selectedIndex = null);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.session,
    required this.selectedIndex,
    required this.onSelect,
    required this.onSkip,
    required this.onNext,
  });

  final QuizSession session;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final question = session.currentQuestion!;
    final answered = selectedIndex != null;
    final isCorrect = answered && selectedIndex == question.correctIndex;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Progress(
            current: session.currentIndex + 1,
            total: session.questionCount,
            correctCount: session.correctCount,
          ),
          const SizedBox(height: 16),
          Text(
            t.quizQuestion,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Text(
              question.translationText,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${question.surahId}:${question.ayahNumber}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: question.options.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final option = question.options[i];
                return _OptionTile(
                  text: option.text,
                  isSelected: selectedIndex == i,
                  isCorrect: answered && i == question.correctIndex,
                  isWrongPick: answered &&
                      selectedIndex == i &&
                      i != question.correctIndex,
                  onTap: answered ? null : () => onSelect(i),
                );
              },
            ),
          ),
          if (answered)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: isCorrect ? AppColors.success : AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isCorrect ? t.quizCorrect : t.quizWrong,
                    style: TextStyle(
                      color: isCorrect ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!answered)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textTertiary,
                      side: const BorderSide(color: AppColors.borderSubtle),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(t.quizSkip),
                  ),
                ),
              if (!answered) const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: answered ? onNext : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.textOnGold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(t.quizNext),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.current,
    required this.total,
    required this.correctCount,
  });

  final int current;
  final int total;
  final int correctCount;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.quizProgress(current, total),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              '$correctCount / $total',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : current / total,
            minHeight: 4,
            backgroundColor: AppColors.surfaceHigh,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrongPick,
    required this.onTap,
  });

  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrongPick;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.borderSubtle;
    Color textColor = AppColors.textPrimary;
    if (isCorrect) {
      borderColor = AppColors.success;
      textColor = AppColors.success;
    } else if (isWrongPick) {
      borderColor = AppColors.error;
      textColor = AppColors.error;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: isCorrect || isWrongPick ? 1.4 : 1),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({required this.session, required this.onPlayAgain});
  final QuizSession session;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events,
                size: 64, color: AppColors.gold),
            const SizedBox(height: 12),
            Text(
              t.quizResultsTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.quizScore(session.correctCount, session.questionCount),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onPlayAgain,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.textOnGold,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(t.quizPlayAgain),
            ),
          ],
        ),
      ),
    );
  }
}
