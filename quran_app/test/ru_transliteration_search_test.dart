import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Тестирует правила фильтрации списка сур — фокус на поиске
/// по **русской транслитерации** (`Аль-Бакара`, `Бакара` и т.п.).
///
/// Это **не** зависит от того, как именно формируется фильтр в
/// `_SurahList`: тест проверяет, что русская транслитерация
/// сматчится, если в списке поиска присутствует `t.surahName(id)`
/// (= ARB `surahName{id}`, который в `ru` локали = кириллическая
/// транслитерация, в `en` локали = английское значение).
class FakeSurah {
  FakeSurah(this.id, this.nameTransliteration, this.nameEn, this.nameAr);
  final int id;
  final String nameTransliteration;
  final String nameEn;
  final String nameAr;
}

/// Эмулирует `AppLocalizations.surahName(id)` для текущей локали:
/// в `ru` — кириллическая транслитерация, в `en` — английское
/// значение. Это поведение ARB-генератора.
const _ruNames = <int, String>{
  1: 'Аль-Фатиха',
  2: 'Аль-Бакара',
  35: 'Фатыр',
  36: 'Ясин',
};
const _enNames = <int, String>{
  1: 'The Opening',
  2: 'The Cow',
  35: 'The Originator',
  36: 'Yaseen',
};
const _ruMeanings = <int, String>{
  1: 'Открывающая',
  2: 'Корова',
  35: 'Творец',
  36: 'Ясин',
};
const _ruTransliterations = <int, String>{
  1: 'Аль-Фатиха',
  2: 'Аль-Бакара',
  35: 'Фатыр',
  36: 'Ясин',
};

String _name(int id, Locale locale) {
  if (locale.languageCode == 'ru') return _ruNames[id] ?? '';
  if (locale.languageCode == 'en') return _enNames[id] ?? '';
  return '';
}

String? _meaning(int id, Locale locale) {
  if (locale.languageCode == 'ru') return _ruMeanings[id];
  if (locale.languageCode == 'en') return _enNames[id];
  return null;
}

String _ruTranslit(int id) => _ruTransliterations[id] ?? '';

/// Копия правил фильтрации из `_SurahList`. Включает поиск по
/// `t.surahName(id)` для текущей локали (русская транслитерация
/// в `ru` локали) + fallback на русскую транслитерацию для любой
/// локали + fallback на русское значение для любой локали.
List<FakeSurah> filter(
  List<FakeSurah> items,
  String query,
  Locale locale,
) {
  if (query.isEmpty) return items;
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return items;
  return items.where((s) {
    if (s.id.toString() == q) return true;
    if (s.nameTransliteration.toLowerCase().contains(q)) return true;
    if (s.nameEn.toLowerCase().contains(q)) return true;
    if (s.nameAr.contains(query.trim())) return true;
    // 5. Локализованное название (русская транслитерация в ru).
    final ln = _name(s.id, locale).toLowerCase();
    if (ln.isNotEmpty && ln.contains(q)) return true;
    // 6. Значение на текущей локали.
    final lm = _meaning(s.id, locale)?.toLowerCase();
    if (lm != null && lm.contains(q)) return true;
    // 7. Fallback: русская транслитерация для **любой** локали.
    final rt = _ruTranslit(s.id).toLowerCase();
    if (rt.isNotEmpty && rt.contains(q)) return true;
    // 8. Fallback: русское значение для **любой** локали.
    final rm = _ruMeanings[s.id]?.toLowerCase();
    if (rm != null && rm.contains(q)) return true;
    return false;
  }).toList();
}

void main() {
  final items = [
    FakeSurah(1, 'Al-Faatiha', 'The Opening', 'الفاتحة'),
    FakeSurah(2, 'Al-Baqara', 'The Cow', 'البقرة'),
    FakeSurah(35, 'Faatir', 'The Originator', 'فاطر'),
    FakeSurah(36, 'Yaseen', 'Yaseen', 'يس'),
  ];

  group('Russian transliteration search (ru locale)', () {
    test('"Аль-Бакара" finds Al-Baqara', () {
      final out = filter(items, 'Аль-Бакара', const Locale('ru'));
      expect(out.map((s) => s.id).toList(), [2]);
    });

    test('"Бакара" finds Al-Baqara (partial)', () {
      final out = filter(items, 'Бакара', const Locale('ru'));
      expect(out.map((s) => s.id).toList(), [2]);
    });

    test('"Аль-Фатиха" finds Al-Faatiha', () {
      final out = filter(items, 'Аль-Фатиха', const Locale('ru'));
      expect(out.map((s) => s.id).toList(), [1]);
    });

    test('"Фатыр" finds surah 35', () {
      final out = filter(items, 'Фатыр', const Locale('ru'));
      expect(out.map((s) => s.id).toList(), [35]);
    });

    test('"Ясин" finds surah 36 (matches both name and meaning)', () {
      final out = filter(items, 'Ясин', const Locale('ru'));
      expect(out.map((s) => s.id).toList(), [36]);
    });

    test('Case-insensitive: "аль-бакара" finds Al-Baqara', () {
      final out = filter(items, 'аль-бакара', const Locale('ru'));
      expect(out.map((s) => s.id).toList(), [2]);
    });
  });

  group('Russian transliteration as fallback in non-ru locale', () {
    test('"Аль-Бакара" finds Al-Baqara even in en locale', () {
      final out = filter(items, 'Аль-Бакара', const Locale('en'));
      // Если поиск по `t.surahName` работает только для текущей
      // локали, "Аль-Бакара" не сматчится в en. Этот тест
      // определяет, нужна ли поддержка RU-транслитерации как
      // fallback в любой локали.
      expect(out.map((s) => s.id).toList(), [2]);
    });
  });

  group('Meaning search still works', () {
    test('"Корова" finds Al-Baqara', () {
      final out = filter(items, 'Корова', const Locale('ru'));
      expect(out.map((s) => s.id).toList(), [2]);
    });
  });
}