import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';

/// Показать модальную карточку слова.
///
/// Используется в [`ReaderScreen`] при тапе на любое слово аята. Если
/// в данный момент играет аудио — плеер предварительно перематывается
/// на слово (через `seekToWord`) и только потом открывается карточка.
Future<void> showWordCard({
  required BuildContext context,
  required WidgetRef ref,
  required Word word,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: AppColors.border, width: 1),
    ),
    builder: (_) => _WordCardContent(word: word),
  );
}

class _WordCardContent extends ConsumerWidget {
  const _WordCardContent({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Set<int>>(
      stream: ref.watch(learningDaoProvider).watchVocabularyIds(),
      builder: (context, snapshot) {
        final inVocab = snapshot.data?.contains(word.id) ?? false;
        return _WordCardBody(word: word, inVocab: inVocab);
      },
    );
  }
}

class _WordCardBody extends StatelessWidget {
  const _WordCardBody({required this.word, required this.inVocab});

  final Word word;
  final bool inVocab;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Arabic word
            Center(
              child: Text(
                word.arabic,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Transliteration / normalized form
            Center(
              child: Text(
                word.normalized,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Translation
            if (word.translation != null && word.translation!.isNotEmpty)
              _MetaRow(
                label: 'Перевод',
                value: word.translation!,
              ),
            if (word.lemma != null && word.lemma!.isNotEmpty)
              _MetaRow(
                label: 'Лемма',
                value: word.lemma!,
              ),
            if (word.root != null && word.root!.isNotEmpty)
              _MetaRow(
                label: 'Корень',
                value: word.root!,
              ),

            // Empty-state for Al-Fatiha words where translation/lemma/root
            // are null (current seed has only the bare word). Future step:
            // populate from a word dictionary JSON.
            if ((word.translation == null || word.translation!.isEmpty) &&
                (word.lemma == null || word.lemma!.isEmpty) &&
                (word.root == null || word.root!.isEmpty))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Перевод и грамматика появятся, когда словарь будет пополнен.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 24),
            const Divider(color: AppColors.borderSubtle, height: 1),
            const SizedBox(height: 16),

            // Add to vocabulary / In vocabulary indicator
            _AddToVocabButton(word: word, inVocab: inVocab),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddToVocabButton extends ConsumerWidget {
  const _AddToVocabButton({required this.word, required this.inVocab});

  final Word word;
  final bool inVocab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (inVocab) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.gold, size: 20),
            SizedBox(width: 8),
            Text(
              'В словаре',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.gold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () async {
          await ref.read(learningDaoProvider).addWord(word.id);
        },
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Добавить в словарь',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.textOnGold,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
