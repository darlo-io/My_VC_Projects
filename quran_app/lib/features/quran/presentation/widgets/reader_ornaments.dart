// Round 9.6 (code review #R1): extracted ornament widgets из
// `lib/features/quran/presentation/reader_screen.dart`.
//
// До этого изменения все 4 класса (`_AyahSeparator`,
// `_OrnamentGlyph`, `_AyahSeparatorPainter`) были в одном 2414-строчном
// god-file. Теперь — отдельный модуль с documented public API.
//
// Используются в `_SingleScrollMushaf` (lineByLine-режим) и
// внутри `Text.rich` (book-mode). API остался 100% обратно
// совместимым с предыдущим поведением — внутренние имена
// переименованы из `_Foo` в `ReaderOrnamentFoo` (public).
import 'package:flutter/material.dart';

import '../../../../core/i18n/arabic_digits.dart';
import '../../../../core/theme/app_colors.dart';

/// Линия-разделитель между аятами в Mushaf-режиме.
///
/// **Round 9.6**: извлечён из `reader_screen.dart` (R1). Параметры
/// `ayahNumber`/`digitColor`/`fontFamily` сохранены для обратной
/// совместимости с будущей фичей "показывать номер аята возле divider".
class ReaderAyahSeparator extends StatelessWidget {
  const ReaderAyahSeparator({
    required this.ayahNumber,
    required this.digitColor,
    this.fontFamily,
    super.key,
  });

  /// Номер аята — не используется визуально (раньше рендерился
  /// внутри ornament'а), но оставлен в API для совместимости с
  /// вызывающим кодом. Сохраняем, чтобы будущая фича
  /// (например, маленькая цифра на линии) могла его использовать.
  final int ayahNumber;

  /// Цвет цифры (legacy, больше не используется).
  final Color digitColor;

  /// Шрифт ornament'а (legacy, больше не используется).
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: CustomPaint(
        painter: _ReaderAyahSeparatorPainter(),
        size: const Size(double.infinity, 2),
      ),
    );
  }
}

/// `CustomPainter` для [_ReaderAyahSeparator]. Round 9.6 (R1):
/// извлечён из `reader_screen.dart` — ранее private `_AyahSeparatorPainter`.
class _ReaderAyahSeparatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final linePaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.4)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    const lineInset = 16.0;
    canvas.drawLine(
      Offset(lineInset, cy),
      Offset(size.width - lineInset, cy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_ReaderAyahSeparatorPainter old) => false;
}

/// Reusable ornament-глиф `۝N` с цифрой **точно по центру**
/// ornament-глифа. Используется в book-mode (внутри `Text.rich`
/// через `WidgetSpan`) и в `_BookTranslationBlock`.
///
/// **Round 9.6**: извлечён из `reader_screen.dart` (R1). API
/// стабильный, signature не меняется.
class ReaderOrnamentGlyph extends StatelessWidget {
  const ReaderOrnamentGlyph({
    required this.ayahNumber,
    required this.digitColor,
    this.fontFamily,
    this.glyphSize = 26,
    this.digitSize = 13,
    super.key,
  });

  final int ayahNumber;
  final String? fontFamily;
  final double glyphSize;
  final double digitSize;
  final Color digitColor;

  @override
  Widget build(BuildContext context) {
    const glyphC = AppColors.gold;
    return SizedBox(
      height: glyphSize + 2,
      width: glyphSize + 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '۝',
            style: TextStyle(
              fontSize: glyphSize,
              height: 1.0,
              color: glyphC,
              fontFamily: fontFamily,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              toArabicDigits(ayahNumber),
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: digitSize,
                height: 1.0,
                color: digitColor,
                fontFamily: fontFamily,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
