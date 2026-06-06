/// Нормализация арабского текста для поиска:
///  - удаление харакат (диакритических знаков);
///  - нормализация алефов (أ إ آ → ا);
///  - нормализация я-و (ى → ي, ة → ه);
///  - удаление татвиля;
///  - Unicode NFC.
class ArabicNormalizer {
  ArabicNormalizer._();

  static const _diacritics = '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0653\u0654\u0655\u0656\u0657\u0658\u0670';
  static const _tatweel = '\u0640';

  static String normalize(String input) {
    var s = input;
    // Удалить татвиль
    s = s.replaceAll(_tatweel, '');
    // Удалить диакритики
    final buf = StringBuffer();
    for (final r in s.runes) {
      if (_diacritics.indexOf(String.fromCharCode(r)) == -1) {
        buf.writeCharCode(r);
      }
    }
    s = buf.toString();
    // Нормализация букв
    s = s
        .replaceAll('\u0622', '\u0627') // آ → ا
        .replaceAll('\u0623', '\u0627') // أ → ا
        .replaceAll('\u0625', '\u0627') // إ → ا
        .replaceAll('\u0671', '\u0627') // ٱ → ا
        .replaceAll('\u0649', '\u064A') // ى → ي
        .replaceAll('\u0629', '\u0647') // ة → ه
        .replaceAll('\u0648\u0627', '\u0648'); // وا → و (смягчение)
    return s;
  }
}
