import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/models/search_hits.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

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
      stream: ref.watch(learningRepositoryProvider).watchVocabularyIds(),
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
    final t = AppLocalizations.of(context);
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
                label: t.wordTranslation,
                value: word.translation!,
              ),
            if (word.lemma != null && word.lemma!.isNotEmpty)
              _MetaRow(
                label: t.wordLemma,
                value: word.lemma!,
              ),
            if (word.root != null && word.root!.isNotEmpty)
              _MetaRow(
                label: t.wordRoot,
                value: word.root!,
              ),

            // "Other words with the same root" — only shown when the
            // current word has a known root. The list is capped at
            // 5 hits to keep the bottom sheet compact.
            if (word.root != null && word.root!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _RelatedWordsSection(root: word.root!, excludeWordId: word.id),
            ],

            // Empty-state for words where translation/lemma/root are
            // all null (the bare-word seed for Al-Fatiha). When the
            // dictionary is filled in, this branch disappears.
            if ((word.translation == null || word.translation!.isEmpty) &&
                (word.lemma == null || word.lemma!.isEmpty) &&
                (word.root == null || word.root!.isEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  t.wordEmptyHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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

class _RelatedWordsSection extends ConsumerWidget {
  const _RelatedWordsSection({
    required this.root,
    required this.excludeWordId,
  });

  final String root;
  final int excludeWordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final repo = ref.watch(searchRepositoryProvider);
    return FutureBuilder<List<WordSearchHit>>(
      future: repo.searchWordsByRoot(
        root: root,
        limit: 5,
        excludeWordId: excludeWordId,
      ),
      builder: (context, snapshot) {
        // Hide the section entirely while loading or when there are
        // no related words. We don't show an empty-state here because
        // a "no other words share this root" message is noise — the
        // user came for the word, not a root census.
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final hits = snapshot.data ?? const <WordSearchHit>[];
        if (hits.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree_outlined,
                    size: 14, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  t.wordSameRoot,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...hits.map(
              (h) => _RelatedWordTile(hit: h),
            ),
          ],
        );
      },
    );
  }
}

class _RelatedWordTile extends StatelessWidget {
  const _RelatedWordTile({required this.hit});
  final WordSearchHit hit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.of(context).maybePop();
          context.go('/reader/${hit.surahId}?ayah=${hit.ayahNumber}');
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(
                hit.arabic,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hit.normalized,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hit.translation != null && hit.translation!.isNotEmpty)
                      Text(
                        hit.translation!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${hit.surahId}:${hit.ayahNumber}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
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
    final t = AppLocalizations.of(context);
    if (inVocab) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.gold, size: 20),
            const SizedBox(width: 8),
            Text(
              t.wordInVocab,
              style: const TextStyle(
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
          await ref.read(learningRepositoryProvider).add(word.id);
        },
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          t.wordAddToVocab,
          style: const TextStyle(
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
