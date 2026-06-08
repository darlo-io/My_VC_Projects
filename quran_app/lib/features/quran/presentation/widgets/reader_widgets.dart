import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ornaments.dart';
import '../../../audio/presentation/word_timing_provider.dart';
import '../../../learning/presentation/word_card.dart';

class AyahTile extends ConsumerStatefulWidget {
  const AyahTile({
    required this.ayah,
    required this.translation,
    required this.fontSize,
    required this.isBookmarked,
    required this.onToggleBookmark,
    super.key,
  });

  final Ayah ayah;
  final String? translation;
  final double fontSize;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;

  @override
  ConsumerState<AyahTile> createState() => _AyahTileState();
}

class _AyahTileState extends ConsumerState<AyahTile> {
  List<Word>? _words;
  bool _loadingWords = false;
  // Token guard против stale-load: при каждом _loadWords() увеличиваем;
  // setState() применяем только если в setState момент токен всё ещё актуален.
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void didUpdateWidget(covariant AyahTile old) {
    super.didUpdateWidget(old);
    if (old.ayah.id != widget.ayah.id) {
      _loadWords();
    }
  }

  Future<void> _loadWords() async {
    final token = ++_loadToken;
    setState(() => _loadingWords = true);
    final list =
        await ref.read(wordsDaoProvider).getByAyah(widget.ayah.id);
    if (!mounted || token != _loadToken) return;
    setState(() {
      _words = list;
      _loadingWords = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AyahNumberBadge(number: widget.ayah.ayahNumber),
              const Spacer(),
              IconButton(
                onPressed: widget.onToggleBookmark,
                icon: BookmarkStar(filled: widget.isBookmarked, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ArabicText(
            ayah: widget.ayah,
            fontSize: widget.fontSize,
            words: _words,
            loading: _loadingWords,
          ),
          if (widget.translation != null) ...[
            const SizedBox(height: 12),
            Text(
              widget.translation!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArabicText extends ConsumerWidget {
  const _ArabicText({
    required this.ayah,
    required this.fontSize,
    required this.words,
    required this.loading,
  });

  final Ayah ayah;
  final double fontSize;
  final List<Word>? words;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Нет данных по словам (не сидированы) — fallback на plain text.
    if (words == null && !loading) {
      return _plainText(ayah.textUthmani);
    }
    if (loading || words == null || words!.isEmpty) {
      return _plainText(ayah.textUthmani);
    }

    final player = ref.watch(audioPlayerControllerProvider);
    final activeSurah = player.surah;
    final isCurrentSurah = activeSurah != null && activeSurah.id == ayah.surahId;
    // Subsample: highlight меняется раз в 50 ms — этого достаточно для глаза.
    // Без subsample parent rebuild 10×/сек → 7 ayahs × 10 = 70 rebuilds/sec
    // для Al-Fatiha, 2860/sec для Al-Baqarah.
    final currentWord = isCurrentSurah
        ? ref.watch(currentWordIdProvider)
        : CurrentWordId.beforeFirst;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        alignment: WrapAlignment.start,
        textDirection: TextDirection.rtl,
            crossAxisAlignment: WrapCrossAlignment.start,
        children: words!.map((w) {
          final isCurrent = w.id == currentWord.value && isCurrentSurah;
          return _WordSpan(
            word: w,
            fontSize: fontSize,
            highlighted: isCurrent,
            onTap: () {
              // Если сейчас играет аудио этой суры — перематываем
              // плеер на тапнутое слово, чтобы подсветка и озвучка
              // шли синхронно с пользовательским фокусом.
              if (isCurrentSurah) {
                seekToWord(ref, w.id);
              }
              // В любом случае открываем WordCard (Learn feature).
              showWordCard(context: context, ref: ref, word: w);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _plainText(String text) {
    return SelectableText(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.justify,
      style: TextStyle(
        fontSize: fontSize,
        height: 2.0,
        color: AppColors.textPrimary,
        fontFamily: 'Amiri',
      ),
    );
  }
}

class _WordSpan extends StatelessWidget {
  const _WordSpan({
    required this.word,
    required this.fontSize,
    required this.highlighted,
    this.onTap,
  });

  final Word word;
  final double fontSize;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: highlighted
              ? AppColors.gold.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: highlighted
              ? Border.all(color: AppColors.gold, width: 1)
              : null,
        ),
        child: Text(
          word.arabic,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: fontSize,
            height: 2.0,
            color: highlighted ? AppColors.gold : AppColors.textPrimary,
            fontFamily: 'Amiri',
            fontWeight: highlighted ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Один стрим на весь экран: множество ID аятов с закладками.
final bookmarkedAyahIdsProvider = StreamProvider<Set<int>>((ref) {
  return ref.watch(bookmarkDaoProvider).watchBookmarkedAyahIds();
});

Future<void> toggleBookmark(
  WidgetRef ref, {
  required Ayah ayah,
  required bool isCurrentlyBookmarked,
}) async {
  final dao = ref.read(bookmarkDaoProvider);
  if (isCurrentlyBookmarked) {
    await dao.deleteByAyah(ayah.id);
  } else {
    await dao.insertBookmark(
      BookmarksCompanion.insert(
        surahId: ayah.surahId,
        ayahId: ayah.id,
        ayahNumber: ayah.ayahNumber,
      ),
    );
  }
}
