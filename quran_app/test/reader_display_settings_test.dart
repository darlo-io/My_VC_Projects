import 'package:test/test.dart';
import 'package:quran_app/features/reader_settings/domain/reader_display_settings.dart';
import 'package:quran_app/features/reader_settings/domain/reader_display_settings_codec.dart';

void main() {
  group('ReaderDisplaySettings defaults', () {
    test('defaults match documented initial values', () {
      const s = ReaderDisplaySettings.defaults;
      expect(s.fontSize, 28.0);
      expect(s.lineHeight, 2.4);
      expect(s.letterSpacing, 0.1);
      expect(s.wordSpacing, 0.0);
      expect(s.fontFamily, 'Amiri');
      expect(s.textWidthPercent, 100.0);
      expect(s.paddingHorizontal, 16.0);
      expect(s.paddingVertical, 8.0);
      expect(s.themeVariant, 'dark');
      expect(s.brightness, 100.0);
      expect(s.translationFontSize, 14.0);
      expect(s.showTranslation, true);
      expect(s.showWordByWord, false);
      expect(s.keepScreenOn, true);
      expect(s.readingMode, 'lineByLine');
    });

    test('themeVariants contains only documented variants', () {
      expect(ReaderDisplaySettings.themeVariants, [
        'dark',
        'sepia',
        'light',
        'parchment',
      ]);
    });

    test('fontFamilies contains 6 supported Quran Arabic fonts', () {
      expect(ReaderDisplaySettings.fontFamilies, [
        'Amiri',
        'KFGQPC Uthman Taha Naskh',
        'PDMS Saleem QuranFont',
        'QPC Hafs',
        'ScheherazadeNew',
        'NotoNaskhArabic',
      ]);
    });

    test('fontFamilyLabels parallels fontFamilies 1-to-1', () {
      expect(ReaderDisplaySettings.fontFamilyLabels.length,
          ReaderDisplaySettings.fontFamilies.length);
    });

    test('fontFamilyIndex returns 0 for unknown family', () {
      expect(ReaderDisplaySettings.fontFamilyIndex('unknown'), 0);
    });

    test('fontFamilyIndex returns correct index for known families', () {
      expect(ReaderDisplaySettings.fontFamilyIndex('Amiri'), 0);
      expect(
          ReaderDisplaySettings.fontFamilyIndex('KFGQPC Uthman Taha Naskh'),
          1);
      expect(ReaderDisplaySettings.fontFamilyIndex('PDMS Saleem QuranFont'),
          2);
      expect(ReaderDisplaySettings.fontFamilyIndex('QPC Hafs'), 3);
      expect(ReaderDisplaySettings.fontFamilyIndex('ScheherazadeNew'), 4);
      expect(ReaderDisplaySettings.fontFamilyIndex('NotoNaskhArabic'), 5);
    });
  });

  group('ReaderDisplaySettings.copyWith clamping', () {
    const base = ReaderDisplaySettings.defaults;

    test('fontSize clamps to [18, 40]', () {
      expect(base.copyWith(fontSize: 5).fontSize, 18.0);
      expect(base.copyWith(fontSize: 100).fontSize, 40.0);
      expect(base.copyWith(fontSize: 30).fontSize, 30.0);
    });

    test('lineHeight clamps to [1.4, 2.6]', () {
      expect(base.copyWith(lineHeight: 1.0).lineHeight, 1.4);
      expect(base.copyWith(lineHeight: 5.0).lineHeight, 2.6);
    });

    test('letterSpacing clamps to [0, 2]', () {
      expect(base.copyWith(letterSpacing: -1).letterSpacing, 0.0);
      expect(base.copyWith(letterSpacing: 10).letterSpacing, 2.0);
    });

    test('wordSpacing clamps to [0, 4]', () {
      expect(base.copyWith(wordSpacing: -0.5).wordSpacing, 0.0);
      expect(base.copyWith(wordSpacing: 100).wordSpacing, 4.0);
    });

    test('textWidthPercent clamps to [70, 100]', () {
      expect(base.copyWith(textWidthPercent: 50).textWidthPercent, 70.0);
      expect(base.copyWith(textWidthPercent: 110).textWidthPercent, 100.0);
    });

    test('paddingHorizontal clamps to [8, 32]', () {
      // Горизонтальный отступ: 0 (вплотную к краям) — 32.
      // Раньше было 8 — 32, что блокировало значение 0.
      expect(base.copyWith(paddingHorizontal: 0).paddingHorizontal, 0.0);
      expect(base.copyWith(paddingHorizontal: -10).paddingHorizontal, 0.0);
      expect(base.copyWith(paddingHorizontal: 100).paddingHorizontal, 32.0);
    });

    test('paddingVertical clamps to [8, 32]', () {
      expect(base.copyWith(paddingVertical: 1).paddingVertical, 8.0);
      expect(base.copyWith(paddingVertical: 64).paddingVertical, 32.0);
    });

    test('brightness clamps to [60, 100]', () {
      expect(base.copyWith(brightness: 0).brightness, 60.0);
      expect(base.copyWith(brightness: 120).brightness, 100.0);
    });

    test('translationFontSize clamps to [10, 24]', () {
      expect(base.copyWith(translationFontSize: 5).translationFontSize, 10.0);
      expect(base.copyWith(translationFontSize: 50).translationFontSize, 24.0);
    });

    test('themeVariant rejects unknown id → keeps current', () {
      const s = base; // themeVariant='dark'
      expect(s.copyWith(themeVariant: 'neon').themeVariant, 'dark');
      expect(s.copyWith(themeVariant: 'sepia').themeVariant, 'sepia');
    });

    test('fontFamily rejects unknown id → keeps current', () {
      const s = base; // fontFamily='Amiri'
      expect(s.copyWith(fontFamily: 'ComicSans').fontFamily, 'Amiri');
      expect(s.copyWith(fontFamily: 'ScheherazadeNew').fontFamily,
          'ScheherazadeNew');
      expect(s.copyWith(fontFamily: 'KFGQPC Uthman Taha Naskh').fontFamily,
          'KFGQPC Uthman Taha Naskh');
    });

    test('readingMode accepts only book/lineByLine', () {
      expect(base.copyWith(readingMode: 'book').readingMode, 'book');
      expect(base.copyWith(readingMode: 'lineByLine').readingMode, 'lineByLine');
      expect(base.copyWith(readingMode: 'scroll').readingMode, 'lineByLine');
      // Empty string → falls back to default ('lineByLine').
      expect(base.copyWith(readingMode: '').readingMode, 'lineByLine');
      // 'BOOK' (uppercase) is treated as unknown → fallback to default.
      // Это контракт: readingMode хранится в SharedPreferences всегда
      // в lowercase; UI/AppPreferences гарантируют lowercase до записи.
      expect(base.copyWith(readingMode: 'BOOK').readingMode, 'lineByLine');
    });

    test('copyWith preserves other fields when only one changed', () {
      final changed = base.copyWith(fontSize: 36);
      expect(changed.lineHeight, base.lineHeight);
      expect(changed.translationFontSize, base.translationFontSize);
      expect(changed.themeVariant, base.themeVariant);
      expect(changed.keepScreenOn, base.keepScreenOn);
    });
  });

  group('ReaderDisplaySettings equality', () {
    test('two instances with same fields are equal', () {
      const a = ReaderDisplaySettings.defaults;
      const b = ReaderDisplaySettings.defaults;
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different fields make instances unequal', () {
      const a = ReaderDisplaySettings.defaults;
      final b = a.copyWith(fontSize: 36);
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('translationFontSize change affects equality', () {
      const a = ReaderDisplaySettings.defaults;
      final b = a.copyWith(translationFontSize: 18);
      expect(a, isNot(equals(b)));
    });

    test('showTranslation toggle affects equality', () {
      const a = ReaderDisplaySettings.defaults;
      final b = a.copyWith(showTranslation: false);
      expect(a, isNot(equals(b)));
    });
  });

  group('ReaderDisplaySettingsCodec', () {
    const codec = ReaderDisplaySettingsCodec();

    test('decode(null) returns defaults', () {
      expect(codec.decode(null), equals(ReaderDisplaySettings.defaults));
    });

    test('decode(empty string) returns defaults', () {
      expect(codec.decode(''), equals(ReaderDisplaySettings.defaults));
    });

    test('decode(garbage) returns defaults without throwing', () {
      expect(codec.decode('not-json-at-all'),
          equals(ReaderDisplaySettings.defaults));
      expect(codec.decode('{invalid}'),
          equals(ReaderDisplaySettings.defaults));
      expect(codec.decode('[]'), equals(ReaderDisplaySettings.defaults));
    });

    test('round-trip: encode(decode(s)) == s', () {
      const original = ReaderDisplaySettings.defaults;
      final json = codec.encode(original);
      final decoded = codec.decode(json);
      expect(decoded, equals(original));
    });

    test('round-trip preserves all 14 fields including translationFontSize', () {
      final original = ReaderDisplaySettings.defaults.copyWith(
        fontSize: 32,
        lineHeight: 1.8,
        themeVariant: 'parchment',
        translationFontSize: 20,
        showWordByWord: true,
        keepScreenOn: false,
        readingMode: 'book',
      );
      final json = codec.encode(original);
      final decoded = codec.decode(json);
      expect(decoded.fontSize, 32.0);
      expect(decoded.lineHeight, 1.8);
      expect(decoded.themeVariant, 'parchment');
      expect(decoded.translationFontSize, 20.0);
      expect(decoded.showWordByWord, true);
      expect(decoded.keepScreenOn, false);
      expect(decoded.readingMode, 'book');
    });

    test('forward-compat: unknown JSON fields are ignored', () {
      const s = ReaderDisplaySettings.defaults;
      final jsonWithExtra = '{"fontSize":30,"unknownField":"foo","anotherUnknown":42}';
      final decoded = codec.decode(jsonWithExtra);
      expect(decoded.fontSize, 30.0);
      expect(decoded.themeVariant, s.themeVariant);
      expect(decoded.translationFontSize, s.translationFontSize);
    });

    test('forward-compat: missing field falls back to default', () {
      final partial = '{"fontSize":36}';
      final decoded = codec.decode(partial);
      expect(decoded.fontSize, 36.0);
      expect(decoded.themeVariant, ReaderDisplaySettings.defaults.themeVariant);
      expect(decoded.translationFontSize,
          ReaderDisplaySettings.defaults.translationFontSize);
    });

    test('invalid type in field falls back to default for that field', () {
      final malformed = '{"fontSize":"not-a-number","translationFontSize":18}';
      final decoded = codec.decode(malformed);
      expect(decoded.fontSize, ReaderDisplaySettings.defaults.fontSize);
      expect(decoded.translationFontSize, 18.0);
    });

    test('out-of-range value clamps to bounds', () {
      final overflow = '{"fontSize":1000,"lineHeight":100}';
      final decoded = codec.decode(overflow);
      expect(decoded.fontSize, 40.0);
      expect(decoded.lineHeight, 2.6);
    });

    test('unknown themeVariant keeps default', () {
      final unknown = '{"themeVariant":"neon-pink"}';
      final decoded = codec.decode(unknown);
      expect(decoded.themeVariant, ReaderDisplaySettings.defaults.themeVariant);
    });
  });
}