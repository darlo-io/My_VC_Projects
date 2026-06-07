import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/search/arabic_normalizer.dart';

void main() {
  group('ArabicNormalizer', () {
    test('removes diacritics (харакат)', () {
      expect(ArabicNormalizer.normalize('بِسْمِ'), 'بسم');
      expect(ArabicNormalizer.normalize('الْحَمْدُ'), 'الحمد');
    });

    test('normalizes alef variants to bare alef', () {
      expect(ArabicNormalizer.normalize('أ'), 'ا');
      expect(ArabicNormalizer.normalize('إ'), 'ا');
      expect(ArabicNormalizer.normalize('آ'), 'ا');
      expect(ArabicNormalizer.normalize('ٱ'), 'ا');
    });

    test('normalizes ya-marbuta → ha, alef-maqsura → ya', () {
      expect(ArabicNormalizer.normalize('الرحمة'), 'الرحمه');
      expect(ArabicNormalizer.normalize('موسى'), 'موسي');
    });

    test('removes tatweel', () {
      expect(ArabicNormalizer.normalize('بـسم'), 'بسم');
    });

    test('returns empty string for empty input', () {
      expect(ArabicNormalizer.normalize(''), '');
    });

    test('leaves non-arabic text unchanged', () {
      expect(ArabicNormalizer.normalize('hello'), 'hello');
      expect(ArabicNormalizer.normalize('123'), '123');
    });

    test('is idempotent', () {
      const samples = ['بِسْمِ اللَّهِ', 'الرَّحْمَٰنِ الرَّحِيمِ', 'اهْدِنَا'];
      for (final s in samples) {
        final once = ArabicNormalizer.normalize(s);
        final twice = ArabicNormalizer.normalize(once);
        expect(twice, once, reason: 'normalize is not idempotent for "$s"');
      }
    });
  });
}
