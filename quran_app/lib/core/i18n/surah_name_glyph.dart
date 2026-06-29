// Глифовые surrogate-строки для отрисовки арабских названий сур.
//
// Шрифты `Surah Name V4.ttf` и `Surah Name V2.ttf` кодируют названия
// сур в **Unicode Private Use Area**: glyph `surah001` соответствует
// codepoint `U+E001`, `surah002` — `U+E002`, и т.д. до
// `surah114` → `U+E072`. Возвращаемая строка содержит ровно один
// символ из этого диапазона; для рендеринга её нужно использовать
// с `TextStyle.fontFamily` соответствующего шрифта (см. константы
// ниже).
//
// Формат glyph-имени (`surah001`, `surah002`, …) используется в
// этих TrueType-шрифтах как имя глифа внутри файла, а в Unicode
// они маппятся 1:1 в последовательные PUA-codepoints начиная с
// `U+E001`. Поэтому `id ∈ 1..114` соответствует codepoint
// `0xE000 + id`.
//
// Перед использованием — убедитесь, что шрифт зарегистрирован в
// `pubspec.yaml` (families [surahNameV4FontFamily] и
// [surahNameV2FontFamily]) и в `TextStyle.fontFamily` указан именно
// соответствующий `family`-ключ.

/// Имя семейства шрифта в `pubspec.yaml` для экрана выбора суры.
const String surahNameV4FontFamily = 'Surah Name V4';

/// Имя семейства шрифта в `pubspec.yaml` для экрана чтения суры.
const String surahNameV2FontFamily = 'Surah Name V2';

/// База Unicode Private Use Area, начиная с которой glyph `surah001`
/// маппится в `Surah Name V*.ttf`. `id = 1` → `0xE001`, `id = 114` →
/// `0xE072`.
const int surahNameGlyphBase = 0xE000;

/// Возвращает один-символьную строку для глифа суры с [id] (1..114).
/// При `id` вне допустимого диапазона (включая 0 и > 114) возвращается
/// пустая строка — рендеринг безопасно деградирует в «ничего».
String surahNameGlyph(int id) {
  if (id < 1 || id > 114) return '';
  return String.fromCharCode(surahNameGlyphBase + id);
}
