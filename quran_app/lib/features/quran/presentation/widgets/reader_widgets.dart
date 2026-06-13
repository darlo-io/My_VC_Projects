import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ornaments.dart';
import '../../../audio/presentation/word_timing_provider.dart';
import '../../../learning/presentation/word_card.dart';
import 'notes_panel.dart';

class AyahTile extends ConsumerStatefulWidget {
  const AyahTile({
    required this.ayah,
    required this.translation,
    required this.fontSize,
    required this.isBookmarked,
    required this.onToggleBookmark,
    this.lineByLine = true,
    this.tileKey,
    super.key,
  });

  final Ayah ayah;
  final String? translation;
  final double fontSize;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;

  /// Опциональный [GlobalKey], прокинутый из `_SingleScrollMushaf`
  /// для трекинга реальной высоты / позиции каждого аята в
  /// viewport'е. Используется `findRenderObject()` → `localToGlobal(Offset.zero)`
  /// в `_onScroll` для точного определения "какой аят сейчас
  /// в нижней части viewport'а" (вместо предположения `tileExtent = 220`).
  ///
  /// Передаётся **только** в lineByLine-режиме (где каждый аят —
  /// отдельный `AyahTile` widget). В book-режиме все аяты
  /// объединены в один `Text`-поток, и RenderBox-логика
  /// недоступна.
  final GlobalKey? tileKey;

  /// Режим чтения: `true` (по умолчанию) — арабские слова идут
  /// в `Wrap` с `WrapAlignment.center`, визуально выровнены
  /// по центру viewport'а и переносятся построчно (соответствует
  /// референсу `docs/images/read line by line.png`). `false` —
  /// «книжный» режим: `Text` (не `SelectableText` — последний
  /// перехватывает HitTest) с `TextAlign.justify`, каждое слово
  /// в одну длинную строку.
  final bool lineByLine;

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
        await ref.read(quranRepositoryProvider).wordsForAyahViaWordsDao(widget.ayah.id);
    if (!mounted || token != _loadToken) return;
    setState(() {
      _words = list;
      _loadingWords = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Здесь НЕТ GoldFrame — рамка рисуется один раз на всю
    // Mushaf-область в [ReaderScreen]. Оборачивать каждый аят в свою
    // рамку — нарушает референс, где рамка одна и обнимает ВСЕ
    // аяты суры (см. `docs/images/read line by line.png`).
    //
    // OrnateDivider тоже НЕ здесь — разделитель между аятами
    // рисует [_SingleScrollMushaf._AyahSeparator] в `reader_screen.dart`,
    // чтобы можно было пропустить divider перед первым аятом.
    //
    // Build разбит на 3 приватных widget'а для читаемости
    // (см. [AyahTile] god-build до рефакторинга — 50 строк):
    //   1. [_AyahHeader]    — Row: badge + note + bookmark
    //   2. [_ArabicTextBody] — арабский (Wrap/Text) + words
    //   3. [_AyahTranslation] — перевод (опционально)
    return Padding(
      // [widget.tileKey] НЕ должен быть на обёртке Padding — иначе
      // `Scrollable.ensureVisible(alignment: 0.5)` отцентрирует
      // **весь Padding-блок** (с `vertical: 8`), и аят (внутри
      // Column) сдвинется **вниз** на 8px + высота header'а
      // (_AyahHeader, _ArabicTextBody). Это даёт систематическое
      // смещение ±(headerHeight + 8px) — аят 10 отображается как
      // аят 8, аят 5 как аят 3, и т.д.
      //
      // Переносим `key` на **внутренний** Column — именно он
      // содержит визуальный «центр тяжести» аята (header + текст
      // + translation). `Scrollable.ensureVisible(alignment: 0.5)`
      // отцентрирует Column в viewport'е, и аят появится точно
      // в центре.
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        key: widget.tileKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AyahHeader(
            ayah: widget.ayah,
            isBookmarked: widget.isBookmarked,
            onToggleBookmark: widget.onToggleBookmark,
          ),
          const SizedBox(height: 12),
          _ArabicTextBody(
            ayah: widget.ayah,
            fontSize: widget.fontSize,
            words: _words,
            loading: _loadingWords,
            lineByLine: widget.lineByLine,
          ),
          if (widget.translation != null) ...[
            const SizedBox(height: 14),
            _AyahTranslation(text: widget.translation!),
          ],
        ],
      ),
    );
  }
}

/// Header одного аята: gold 8-point star badge слева, и
/// кнопки заметки + закладки справа.
class _AyahHeader extends StatelessWidget {
  const _AyahHeader({
    required this.ayah,
    required this.isBookmarked,
    required this.onToggleBookmark,
  });

  final Ayah ayah;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AyahNumberBadge(number: ayah.ayahNumber),
        const Spacer(),
        _NoteButton(ayahId: ayah.id),
        const SizedBox(width: 4),
        IconButton(
          onPressed: onToggleBookmark,
          icon: BookmarkStar(filled: isBookmarked, size: 22),
        ),
      ],
    );
  }
}

/// Блок перевода под арабским текстом. Отдельный widget —
/// чтобы родительский [AyahTile.build] оставался компактным,
/// и при отсутствии перевода (например, для не-выбранного
/// translationLang) мы рендерим только `if`-секцию без
/// разделителя.
class _AyahTranslation extends StatelessWidget {
  const _AyahTranslation({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.6,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _ArabicTextBody extends ConsumerWidget {
  const _ArabicTextBody({
    required this.ayah,
    required this.fontSize,
    required this.words,
    required this.loading,
    required this.lineByLine,
  });

  final Ayah ayah;
  final double fontSize;
  final List<Word>? words;
  final bool loading;
  final bool lineByLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Нет данных по словам — fallback на plain text.
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

    if (!lineByLine) {
      // «Книжный» режим: всё одной строкой (`Text` с
      // `TextAlign.justify`). Не используем Wrap с alignment —
      // там строки не центрируются и приходится жертвовать
      // переносами.
      return _plainText(ayah.textUthmani);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        // `WrapAlignment.center` центрирует каждую визуальную
        // строку арабского текста по горизонтали — соответствует
        // референсу `read line by line.png`, где строки аята
        // центрированы, а не прижаты к правому краю (как было
        // с `WrapAlignment.start` в RTL). Слова по-прежнему
        // идут справа-налево, но контейнер строки — по центру.
        alignment: WrapAlignment.center,
        textDirection: TextDirection.rtl,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 4,
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
    // Используем `Text` (а не `SelectableText`): `SelectableText`
    // перехватывает HitTest для cursor/выделения, и тап НЕ
    // доходит до родительского Mushaf-GestDetector — toggle
    // панелей не срабатывает поверх текста. В Mushaf выделение
    // не нужно (в печатной Mushaf текст тоже не выделяется),
    // поэтому `Text` — лучший компромисс.
    return Text(
      text,
      textDirection: TextDirection.rtl,
      // Center-выровненный текст для соответствия референсу.
      // `TextAlign.justify` (был) создавал неприятные большие
      // пробелы между словами в коротких аятах. Но в «книжном»
      // режиме `lineByLine == false` — принудительно justify
      // для длинного потока текста без центрирования.
      textAlign: lineByLine ? TextAlign.center : TextAlign.justify,
      style: TextStyle(
        fontSize: fontSize,
        // 2.2 — соответствует референсу: вертикальный
        // межстрочный интервал ~1.2x от размера шрифта.
        height: 2.2,
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
  return ref.watch(bookmarksRepositoryProvider).watchBookmarkedAyahIds();
});

Future<bool> toggleBookmark(
  WidgetRef ref, {
  required Ayah ayah,
  required bool isCurrentlyBookmarked,
}) {
  return ref.read(bookmarksRepositoryProvider).toggle(
        surahId: ayah.surahId,
        ayahId: ayah.id,
        ayahNumber: ayah.ayahNumber,
        isCurrentlyBookmarked: isCurrentlyBookmarked,
      );
}

/// Маленькая иконка-заметка с бейджем-счётчиком.
/// При тапе открывает [showNotesPanel] для текущего аята.
class _NoteButton extends ConsumerWidget {
  const _NoteButton({required this.ayahId});
  final int ayahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countStream =
        ref.watch(notesRepositoryProvider).watchCountForAyah(ayahId);
    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => _openNotesFor(context, ref, ayahId),
              icon: const Icon(
                Icons.sticky_note_2_outlined,
                color: AppColors.gold,
                size: 22,
              ),
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnGold,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openNotesFor(BuildContext context, WidgetRef ref, int ayahId) async {
    final ayah = await ref
        .read(quranRepositoryProvider)
        .getAyah(ayahId);
    if (ayah == null || !context.mounted) return;
    unawaited(showNotesPanel(context: context, ref: ref, ayah: ayah));
  }
}
