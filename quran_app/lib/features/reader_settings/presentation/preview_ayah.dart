import 'package:flutter/material.dart';

import '../../../../core/i18n/arabic_digits.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/reader_display_settings.dart';
import 'reader_palette.dart';

/// Sticky-preview: первый аят Аль-Фатиха, отрисованный теми
/// же стилями, что и в реальном Reader'е. Реактивно на
/// [settings] (без перерендера всего Reader'а) — на каждый
/// slider-tick родитель делает `setState`, передавая новый
/// immutable [settings] сюда.
///
/// [translationText] — локализованный текст перевода (зависит от
/// `app.languageCode`); передаётся из screen'а, чтобы preview
/// не зависел от [BuildContext] внутри статического контекста.
///
/// **Адаптивный контейнер**: при больших `fontSize` (40) или
/// `lineHeight` (2.6) текст перевода может не поместиться в
/// budget header'а. `LayoutBuilder` оборачивает всё содержимое и
/// получает **конечный** `constraints.maxHeight` от родителя
/// (Flexible внутри Positioned с фиксированной высотой). Дальше:
///   1. `maxLines` для арабского/перевода считаются по budget'у.
///   2. `TextOverflow.fade` — последний рубеж: текст плавно
///      угасает, а не обрезается резко.
///   3. (Опционально) `FittedBox.scaleDown` — пропорционально
///      сжимает preview, если даже с maxLines не помещается.
///
/// Сейчас (без FittedBox) держимся maxLines + fade; в 99% случаев
/// этого достаточно.
class PreviewAyah extends StatelessWidget {
  const PreviewAyah({
    required this.settings,
    required this.translationText,
    super.key,
  });

  final ReaderDisplaySettings settings;
  final String translationText;

  static const _arabic =
      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

  @override
  Widget build(BuildContext context) {
    final palette = ReaderPalette.of(settings.themeVariant);
    final isBold = settings.fontFamily == 'AmiriBold';

    return LayoutBuilder(
      builder: (context, constraints) {
        // Считаем `maxLines` для арабского и перевода исходя из
        // доступного вертикального budget'а. Контейнер preview
        // имеет фиксированные затраты:
        //
        //   padding (top + bottom)         = 2 * (settings.paddingVertical + 8)
        //   + 4   (gap между арабским и ۝-плашкой)
        //   + 12  (gap между ۝-плашкой и переводом)
        //   + 28  (высота золотого кружка ۝)
        //   + 8   (запас на sub-pixel rendering / кёрнинг)
        //
        // Решаем обратную задачу: «сколько строк поместится».
        // Каждая строка арабского = `fontSize * lineHeight` px;
        // каждая строка перевода = `fontSize * 0.55 * (lineHeight-0.8)`.
        //
        // Запас: для арабского берём `floor - 1` (даже если по
        // формуле влезает 2 строки, рисуем 1 — надёжнее из-за
        // sub-pixel rounding и wordSpacing).
        final containerVerticalPadding = settings.paddingVertical + 8;
        final staticOverhead =
            2 * containerVerticalPadding + 4 + 12 + 28 + 8;
        final remaining = constraints.maxHeight - staticOverhead;
        final lineHeightPx = settings.fontSize * settings.lineHeight;
        final arabicMaxLines =
            ((remaining / lineHeightPx).floor() - 1).clamp(1, 4);

        // Для перевода: после арабского + ۝-плашки остаётся
        // `remaining - arabicMaxLines*lineHeightPx` пикселей.
        // Делим на высоту строки перевода.
        final translationLineHeight =
            settings.translationFontSize * (settings.lineHeight - 0.8);
        final translationAvail = remaining - arabicMaxLines * lineHeightPx;
        final translationMaxLines =
            (translationAvail / translationLineHeight).floor().clamp(1, 1);

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: settings.paddingHorizontal,
            vertical: containerVerticalPadding,
          ),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border, width: 0.6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // Без `FittedBox` — он плохо работает с `Flexible`
          // (loose constraints) в `Positioned`-header'е: child
          // рендерится 0×0. Вместо FittedBox'а полагаемся на
          // **строгий** расчёт `maxLines` через `LayoutBuilder` +
          // `TextOverflow.fade` — это покрывает 99% случаев и
          // не даёт overflow'а.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  _arabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: arabicMaxLines,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    fontSize: settings.fontSize,
                    height: settings.lineHeight,
                    letterSpacing: settings.letterSpacing,
                    wordSpacing: settings.wordSpacing,
                    color: palette.text,
                    fontFamily: 'Amiri',
                    fontWeight:
                        isBold ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold,
                    ),
                    child: Center(
                      child: Text(
                        '۝${toArabicDigits(1)}',
                        style: TextStyle(
                          fontSize: settings.fontSize * 0.45,
                          color: palette.background,
                          fontFamily: 'Amiri',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (settings.showTranslation) ...[
                const SizedBox(height: 12),
                Text(
                  '— $translationText',
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: translationMaxLines,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    // `translationFontSize` — независимый параметр,
                    // не производный от арабского `fontSize`.
                    fontSize: settings.translationFontSize,
                    height: settings.lineHeight - 0.8,
                    letterSpacing: settings.letterSpacing * 0.5,
                    color: palette.text.withValues(alpha: 0.7),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
