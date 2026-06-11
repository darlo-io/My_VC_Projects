/// Конвертация чисел в арабские цифры (U+0660..U+0669) для
/// Mushaf-вёрстки. Используется в `_buildBookStyle` (номера
/// аятов в круглых скобках) и в `_BookTranslationBlock` (подписи
/// переводов).
///
/// До рефакторинга эта функция дублировалась в `reader_screen.dart`
/// (2 копии) с разными именами (`_toArabicDigits` / `toArabic`).
/// Теперь — единый helper.
///
/// Латинские цифры (`1`, `2`, `3`...) заменяются на арабские
/// (`١`, `٢`, `٣`...) посимвольно. Не-цифровые символы остаются
/// как есть.
String toArabicDigits(int n) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final s = n.toString();
  final result = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    final idx = c.codeUnitAt(0) - 0x30; // '0' = 0x30
    result.write(
      (idx >= 0 && idx <= 9) ? arabicDigits[idx] : c,
    );
  }
  return result.toString();
}
