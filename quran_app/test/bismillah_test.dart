import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/i18n/bismillah.dart';

void main() {
  group('Bismillah.isBismillah', () {
    test('detects standard Uthmani bismillah (Alquran.cloud)', () {
      expect(
        Bismillah.isBismillah('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'),
        isTrue,
      );
    });

    test('detects bismillah without tatweel alef', () {
      expect(
        Bismillah.isBismillah('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'),
        isTrue,
      );
    });

    test('detects bismillah with leading/trailing whitespace', () {
      expect(
        Bismillah.isBismillah(
          '  بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ  ',
        ),
        isTrue,
      );
    });

    test('detects bismillah + alif-lam-meem of surah 2', () {
      expect(
        // В quran_full.json басмала идёт **без пробела** перед
        // остальной частью аята: «بِسْمِ...ٱلرَّحِيمِالٓمٓ».
        Bismillah.isBismillah('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِالٓمٓ'),
        isTrue,
      );
    });

    test('detects bismillah + rest of surah 112 (Al-Ikhlas)', () {
      expect(
        Bismillah.isBismillah(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِقُلْ هُوَ ٱللَّهُ أَحَدٌ',
        ),
        isTrue,
      );
    });

    test('rejects surah 9 first ayah (no bismillah)', () {
      expect(
        Bismillah.isBismillah(
          'بَرَآءَةٌۭ مِّنَ ٱللَّهِ وَرَسُولِهِۦٓ إِلَى ٱلَّذِينَ عَٰهَدتُّم مِّنَ ٱلْمُشْرِكِينَ',
        ),
        isFalse,
      );
    });

    test('rejects al-hamdu (ayah 2 of Al-Fatiha)', () {
      expect(
        Bismillah.isBismillah('ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ'),
        isFalse,
      );
    });

    test('rejects empty string', () {
      expect(Bismillah.isBismillah(''), isFalse);
    });

    test('rejects non-arabic text', () {
      expect(Bismillah.isBismillah('Bismillah'), isFalse);
      expect(Bismillah.isBismillah('123'), isFalse);
    });

    test('rejects text shorter than bismillah root', () {
      expect(Bismillah.isBismillah('بِسْمِ'), isFalse);
    });
  });

  group('Bismillah.split', () {
    test('returns (bismala, null) for Al-Fatiha first ayah', () {
      final result = Bismillah.split('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');
      expect(result.basmala, equals(Bismillah.standardText));
      expect(result.rest, isNull);
    });

    test('returns (bismala, "الٓمٓ") with diacritics for surah 2 first ayah', () {
      final result = Bismillah.split(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِالٓمٓ',
      );
      expect(result.basmala, equals(Bismillah.standardText));
      // `rest` сохраняет все диакритики из исходного текста:
      // maddahan (ٓ) над алифом и над мимом. Раньше они удалялись
      // при нормализации корня — это была ошибка, ломавшая
      // отображение харакат в первом аяте.
      expect(result.rest, equals('الٓمٓ'));
    });

    test('returns (bismala, "قُلْ هُوَ ٱللَّهُ أَحَدٌ") with diacritics for surah 112', () {
      final result = Bismillah.split(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِقُلْ هُوَ ٱللَّهُ أَحَدٌ',
      );
      expect(result.basmala, equals(Bismillah.standardText));
      // `rest` сохраняет kasra/fatha/damma/sukun/у алиф-васлы.
      expect(result.rest, equals('قُلْ هُوَ ٱللَّهُ أَحَدٌ'));
    });

    test('returns (null, text) for surah 9 first ayah', () {
      const text = 'بَرَآءَةٌۭ مِّنَ ٱللَّهِ وَرَسُولُهُ';
      final result = Bismillah.split(text);
      expect(result.basmala, isNull);
      expect(result.rest, equals(text));
    });

    test('returns (null, text) for non-bismillah ayah', () {
      const text = 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ';
      final result = Bismillah.split(text);
      expect(result.basmala, isNull);
      expect(result.rest, equals(text));
    });
  });

  group('Bismillah.renderText', () {
    test('returns standardText for bismillah ayah', () {
      expect(
        Bismillah.renderText('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'),
        equals(Bismillah.standardText),
      );
    });

    test('returns standardText for bismillah + rest', () {
      expect(
        Bismillah.renderText(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِالٓمٓ',
        ),
        equals(Bismillah.standardText),
      );
    });

    test('returns null for non-bismillah ayah', () {
      expect(Bismillah.renderText('ٱلْحَمْدُ لِلَّهِ'), isNull);
    });

    test('returns null for null input', () {
      expect(Bismillah.renderText(null), isNull);
    });
  });
}
