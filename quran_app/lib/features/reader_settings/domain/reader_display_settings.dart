/// Immutable набор параметров отображения Reader'а.
///
/// Сериализуется в JSON-строку под ключом `reader.displaySettings`
/// в SharedPreferences (см. [ReaderDisplaySettingsCodec]). Внутри
/// `AppPreferences` есть также по-полевые сеттеры для
/// обратной совместимости со старым кодом (`setFontSize`,
/// `setReadingMode`, ...): они обновляют как одиночное поле в
/// legacy-ключе, так и единый snapshot в `reader.displaySettings`.
///
/// Все поля уже проклемплены в [ReaderDisplaySettings.fromJson] и
/// [ReaderDisplaySettings.copyWith]. Нетривиальные инварианты:
///   - `fontSize ∈ [18, 40]`
///   - `lineHeight ∈ [1.4, 2.6]`
///   - `letterSpacing ∈ [0, 2]`
///   - `wordSpacing ∈ [0, 4]`
///   - `textWidthPercent ∈ [70, 100]`
///   - `paddingHorizontal ∈ [8, 32]`
///   - `paddingVertical ∈ [8, 32]`
///   - `brightness ∈ [60, 100]`
///   - `translationFontSize ∈ [10, 24]`
///   - `themeVariant ∈ {'dark','sepia','light','parchment'}`
///   - `fontFamily ∈ {'AmiriRegular','AmiriBold'}` — см. [fontFamilies]
class ReaderDisplaySettings {
  const ReaderDisplaySettings({
    required this.fontSize,
    required this.lineHeight,
    required this.letterSpacing,
    required this.wordSpacing,
    required this.fontFamily,
    required this.textWidthPercent,
    required this.paddingHorizontal,
    required this.paddingVertical,
    required this.themeVariant,
    required this.brightness,
    required this.translationFontSize,
    required this.showTranslation,
    required this.showWordByWord,
    required this.keepScreenOn,
    required this.readingMode,
  });

  final double fontSize;
  final double lineHeight;
  final double letterSpacing;
  final double wordSpacing;

  /// `'AmiriRegular'` или `'AmiriBold'`.
  final String fontFamily;

  /// Ширина полосы текста в процентах от ширины экрана.
  final double textWidthPercent;

  final double paddingHorizontal;
  final double paddingVertical;

  /// `'dark' | 'sepia' | 'light' | 'parchment'`.
  final String themeVariant;

  /// Яркость экрана в процентах (60..100).
  final double brightness;

  /// **Размер шрифта перевода** — независим от арабского
  /// `fontSize`. Позволяет увеличить перевод (для слабовидящих
  /// пользователей) без увеличения арабского, или наоборот —
  /// уменьшить перевод, чтобы он не «съедал» экран при длинных
  /// аятах. Default 14 пикс. (соответствует старому
  /// `fontSize * 0.55` ≈ 15.4 — уменьшили до 14 для
  /// единообразия с Mushaf).
  final double translationFontSize;

  final bool showTranslation;
  final bool showWordByWord;
  final bool keepScreenOn;

  /// `'lineByLine' | 'book'`.
  final String readingMode;

  // ─── Allowed values ───────────────────────────────────────────

  static const List<String> themeVariants = [
    'dark',
    'sepia',
    'light',
    'parchment',
  ];

  /// 4 арабских шрифта для Quran.
  /// Каждое значение — это `family` name из `pubspec.yaml` fonts.
  /// Шрифты с несколькими начертаниями (Amiri, Aref Ruqaa) имеют
  /// Regular + Bold варианты — Flutter различает их через
  /// `TextStyle.fontWeight`. Variable fonts (Scheherazade New)
  /// хранятся в одном файле.
  static const List<String> fontFamilies = [
    'Amiri',
    'ScheherazadeNew',
    'NotoNaskhArabic',
    'ArefRuqaa',
  ];

  /// Локализованные имена шрифтов для UI. Параллельны
  /// [fontFamilies] по индексу.
  static const List<String> fontFamilyLabels = [
    'Amiri',
    'Scheherazade New',
    'Noto Naskh Arabic',
    'Aref Ruqaa',
  ];

  /// Индекс семейства в [fontFamilies]. 0 для неизвестного.
  static int fontFamilyIndex(String family) {
    final i = fontFamilies.indexOf(family);
    return i < 0 ? 0 : i;
  }

  // ─── Defaults ─────────────────────────────────────────────────

  static const defaults = ReaderDisplaySettings(
    fontSize: 28.0,
    lineHeight: 2.4,
    letterSpacing: 0.1,
    wordSpacing: 0.0,
    fontFamily: 'Amiri',
    textWidthPercent: 100.0,
    paddingHorizontal: 16.0,
    paddingVertical: 8.0,
    themeVariant: 'dark',
    brightness: 100.0,
    translationFontSize: 14.0,
    showTranslation: true,
    showWordByWord: false,
    keepScreenOn: true,
    readingMode: 'lineByLine',
  );

  // ─── copyWith + clamp ─────────────────────────────────────────

  ReaderDisplaySettings copyWith({
    double? fontSize,
    double? lineHeight,
    double? letterSpacing,
    double? wordSpacing,
    String? fontFamily,
    double? textWidthPercent,
    double? paddingHorizontal,
    double? paddingVertical,
    String? themeVariant,
    double? brightness,
    double? translationFontSize,
    bool? showTranslation,
    bool? showWordByWord,
    bool? keepScreenOn,
    String? readingMode,
  }) {
    return ReaderDisplaySettings(
      fontSize: _clamp(fontSize ?? this.fontSize, 18.0, 40.0),
      lineHeight: _clamp(lineHeight ?? this.lineHeight, 1.4, 2.6),
      letterSpacing: _clamp(letterSpacing ?? this.letterSpacing, 0.0, 2.0),
      wordSpacing: _clamp(wordSpacing ?? this.wordSpacing, 0.0, 4.0),
      fontFamily: fontFamilies.contains(fontFamily ?? this.fontFamily)
          ? (fontFamily ?? this.fontFamily)
          : this.fontFamily,
      textWidthPercent:
          _clamp(textWidthPercent ?? this.textWidthPercent, 70.0, 100.0),
      paddingHorizontal:
          _clamp(paddingHorizontal ?? this.paddingHorizontal, 8.0, 32.0),
      paddingVertical:
          _clamp(paddingVertical ?? this.paddingVertical, 8.0, 32.0),
      themeVariant: themeVariants.contains(themeVariant ?? this.themeVariant)
          ? (themeVariant ?? this.themeVariant)
          : this.themeVariant,
      brightness: _clamp(brightness ?? this.brightness, 60.0, 100.0),
      translationFontSize: _clamp(
        translationFontSize ?? this.translationFontSize,
        10.0,
        24.0,
      ),
      showTranslation: showTranslation ?? this.showTranslation,
      showWordByWord: showWordByWord ?? this.showWordByWord,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      readingMode:
          (readingMode ?? this.readingMode).contains('book') ? 'book' : 'lineByLine',
    );
  }

  static double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  // ─── Equality ─────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderDisplaySettings &&
        other.fontSize == fontSize &&
        other.lineHeight == lineHeight &&
        other.letterSpacing == letterSpacing &&
        other.wordSpacing == wordSpacing &&
        other.fontFamily == fontFamily &&
        other.textWidthPercent == textWidthPercent &&
        other.paddingHorizontal == paddingHorizontal &&
        other.paddingVertical == paddingVertical &&
        other.themeVariant == themeVariant &&
        other.brightness == brightness &&
        other.translationFontSize == translationFontSize &&
        other.showTranslation == showTranslation &&
        other.showWordByWord == showWordByWord &&
        other.keepScreenOn == keepScreenOn &&
        other.readingMode == readingMode;
  }

  @override
  int get hashCode => Object.hash(
        fontSize,
        lineHeight,
        letterSpacing,
        wordSpacing,
        fontFamily,
        textWidthPercent,
        paddingHorizontal,
        paddingVertical,
        themeVariant,
        brightness,
        translationFontSize,
        showTranslation,
        showWordByWord,
        keepScreenOn,
        readingMode,
      );
}
