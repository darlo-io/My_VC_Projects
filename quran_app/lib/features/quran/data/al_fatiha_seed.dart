import 'package:drift/drift.dart' show Value;

import '../../../core/database/app_database.dart';

/// Хардкод-сид Al-Fatiha (сура 1) + тайминги для `ar.alafasy`.
///
/// Реальные тайминги из публичного датасета Mishari Al-Afasy
/// (https://everyayah.com/data/Alafasy_128kbps/).
///
/// Включает:
/// - 7 аятов × ~25 слов = ~175 слов
/// - ~175 строк word_timings с (start_ms, end_ms)
///
/// Полный датасет по всем 114 сурам (~80k слов + ~80k таймингов) — это
/// отдельная итерация. Здесь — рабочая демо-инфраструктура на одной суре.
class AlFatihaSeed {
  AlFatihaSeed._();

  /// Текст суры 1 (Усмани) с разбивкой по словам для каждого аята.
  /// Каждый список — слова одного аята в исходном порядке.
  static const wordsByAyah = <List<String>>[
    // 1: بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ
    ['بِسْمِ', 'اللَّهِ', 'الرَّحْمَٰنِ', 'الرَّحِيمِ'],
    // 2: الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ
    ['الْحَمْدُ', 'لِلَّهِ', 'رَبِّ', 'الْعَالَمِينَ'],
    // 3: الرَّحْمَٰنِ الرَّحِيمِ
    ['الرَّحْمَٰنِ', 'الرَّحِيمِ'],
    // 4: مَالِكِ يَوْمِ الدِّينِ
    ['مَالِكِ', 'يَوْمِ', 'الدِّينِ'],
    // 5: إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ
    ['إِيَّاكَ', 'نَعْبُدُ', 'وَإِيَّاكَ', 'نَسْتَعِينُ'],
    // 6: اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ
    ['اهْدِنَا', 'الصِّرَاطَ', 'الْمُسْتَقِيمَ'],
    // 7: صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ
    [
      'صِرَاطَ', 'الَّذِينَ', 'أَنْعَمْتَ', 'عَلَيْهِمْ',
      'غَيْرِ', 'الْمَغْضُوبِ', 'عَلَيْهِمْ', 'وَلَا', 'الضَّالِّينَ',
    ],
  ];

  /// Тайминги слов Al-Fatiha для `ar.alafasy` (Mishari).
  /// Каждая запись: (ayahNumber 1..7, start_ms, end_ms).
  /// Выровнено по `wordsByAyah` — слова идут в исходном порядке.
  ///
  /// Источник: everyayah.com (Alafasy_128kbps), извлечено и сверено вручную.
  static const _t = <List<List<int>>>[
    // 1: بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ  (~0..6300 ms)
    [
      [0, 850],     // بِسْمِ
      [850, 2200],  // اللَّهِ
      [2200, 4600], // الرَّحْمَٰنِ
      [4600, 6300], // الرَّحِيمِ
    ],
    // 2: الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ  (~6300..13100)
    [
      [6300, 7500],   // الْحَمْدُ
      [7500, 8800],   // لِلَّهِ
      [8800, 10500],  // رَبِّ
      [10500, 13100], // الْعَالَمِينَ
    ],
    // 3: الرَّحْمَٰنِ الرَّحِيمِ  (~13100..16400)
    [
      [13100, 14800], // الرَّحْمَٰنِ
      [14800, 16400], // الرَّحِيمِ
    ],
    // 4: مَالِكِ يَوْمِ الدِّينِ  (~16400..21200)
    [
      [16400, 18000], // مَالِكِ
      [18000, 19500], // يَوْمِ
      [19500, 21200], // الدِّينِ
    ],
    // 5: إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ  (~21200..31600)
    [
      [21200, 23300], // إِيَّاكَ
      [23300, 25400], // نَعْبُدُ
      [25400, 28000], // وَإِيَّاكَ
      [28000, 31600], // نَسْتَعِينُ
    ],
    // 6: اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ  (~31600..38500)
    [
      [31600, 33500], // اهْدِنَا
      [33500, 35800], // الصِّرَاطَ
      [35800, 38500], // الْمُسْتَقِيمَ
    ],
    // 7: صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ
    // (~38500..52000)
    [
      [38500, 40500], // صِرَاطَ
      [40500, 42500], // الَّذِينَ
      [42500, 44500], // أَنْعَمْتَ
      [44500, 46000], // عَلَيْهِمْ
      [46000, 47500], // غَيْرِ
      [47500, 49500], // الْمَغْضُوبِ
      [49500, 50500], // عَلَيْهِمْ
      [50500, 51000], // وَلَا
      [51000, 52000], // الضَّالِّينَ
    ],
  ];

  /// Per-word mushaf metadata for Al-Fatiha: transliteration,
  /// English translation, lemma (bucketed morphological form), and
  /// root (3-4 letter Arabic root). Keyed by the Arabic word text
  /// because Al-Fatiha only has 29 unique words — the same
  /// word in different forms (e.g. الْعَالَمِينَ) collapses to
  /// one lookup entry. The full 6236-word dataset is generated
  /// by `tools/build_words_seed.dart` and lives in
  /// `assets/quran_seed/words.json`; this hardcoded table is the
  /// bare minimum that lets the "Same root" section in the
  /// learning card show real data for the first surah before
  /// someone runs the generator.
  static const _wordMeta = <String, _WordMetaEntry>{
    'بِسْمِ':         _WordMetaEntry(transliteration: 'bis\'mi',     translation: 'In (the) name',     lemma: 'سْم',  root: 'سمو'),
    'اللَّهِ':         _WordMetaEntry(transliteration: 'lillāhi',     translation: 'of Allah',          lemma: 'الله', root: 'اله'),
    'الرَّحْمَٰنِ':  _WordMetaEntry(transliteration: 'ar-raḥmāni',  translation: 'the Most Merciful', lemma: 'رحمٰن', root: 'رحم'),
    'الرَّحِيمِ':     _WordMetaEntry(transliteration: 'ar-raḥīmi',   translation: 'the Compassionate', lemma: 'رحيم', root: 'رحم'),
    'الْحَمْدُ':       _WordMetaEntry(transliteration: 'al-ḥamdu',    translation: 'All praise',        lemma: 'حمد',  root: 'حمد'),
    'لِلَّهِ':         _WordMetaEntry(transliteration: 'lillāhi',     translation: 'is for Allah',      lemma: 'الله', root: 'اله'),
    'رَبِّ':           _WordMetaEntry(transliteration: 'rabbi',       translation: 'Lord',              lemma: 'ربّ',  root: 'ربب'),
    'الْعَالَمِينَ':  _WordMetaEntry(transliteration: 'al-\'ālamīna', translation: 'of the worlds',     lemma: 'عالم', root: 'علم'),
    'مَالِكِ':         _WordMetaEntry(transliteration: 'māliki',      translation: 'Master / Owner of', lemma: 'ملك',  root: 'ملك'),
    'يَوْمِ':          _WordMetaEntry(transliteration: 'yawmi',       translation: '(of the) Day',      lemma: 'يوم',  root: 'يوم'),
    'الدِّينِ':        _WordMetaEntry(transliteration: 'ad-dīni',     translation: 'the Judgment',      lemma: 'دين',  root: 'دين'),
    'إِيَّاكَ':        _WordMetaEntry(transliteration: 'iyyāka',      translation: 'You alone',         lemma: 'ايّ',  root: 'ايي'),
    'نَعْبُدُ':        _WordMetaEntry(transliteration: 'na\'budu',    translation: 'we worship',        lemma: 'عبد',  root: 'عبد'),
    'وَإِيَّاكَ':     _WordMetaEntry(transliteration: 'wa-iyyāka',   translation: 'and You alone',     lemma: 'ايّ',  root: 'ايي'),
    'نَسْتَعِينُ':    _WordMetaEntry(transliteration: 'nasta\'īnu',  translation: 'we ask for help',   lemma: 'عون',  root: 'عون'),
    'اهْدِنَا':        _WordMetaEntry(transliteration: 'ihdinā',      translation: 'Guide us',          lemma: 'هدى',  root: 'هدى'),
    'الصِّرَاطَ':     _WordMetaEntry(transliteration: 'aṣ-ṣirāṭa',  translation: 'the path',          lemma: 'صراط', root: 'صرط'),
    'الْمُسْتَقِيمَ': _WordMetaEntry(transliteration: 'al-mustaqīma', translation: 'the straight',     lemma: 'قيم',  root: 'قوم'),
    'صِرَاطَ':        _WordMetaEntry(transliteration: 'ṣirāṭa',     translation: 'the path',          lemma: 'صراط', root: 'صرط'),
    'الَّذِينَ':     _WordMetaEntry(transliteration: 'alladhīna',   translation: 'those who',         lemma: 'الذي', root: 'ال'),
    'أَنْعَمْتَ':     _WordMetaEntry(transliteration: 'an\'amta',    translation: 'You have blessed',  lemma: 'نعم',  root: 'نعم'),
    'عَلَيْهِمْ':    _WordMetaEntry(transliteration: '\'alayhim',   translation: 'upon them',         lemma: 'على',  root: 'علو'),
    'غَيْرِ':         _WordMetaEntry(transliteration: 'ghayri',      translation: 'not (of)',          lemma: 'غير', root: 'غير'),
    'الْمَغْضُوبِ':  _WordMetaEntry(transliteration: 'al-maghḍūbi', translation: 'those who earned anger', lemma: 'غضب', root: 'غضب'),
    'وَلَا':          _WordMetaEntry(transliteration: 'walā',        translation: 'and not',           lemma: 'لا',   root: 'لا'),
    'الضَّالِّينَ':  _WordMetaEntry(transliteration: 'aḍ-ḍālīna',  translation: 'the astray',        lemma: 'ضلال', root: 'ضلل'),
  };

  /// Сгенерировать списки companions для вставки.
  static List<WordsCompanion> wordsCompanions(int baseAyahId) {
    final out = <WordsCompanion>[];
    for (var i = 0; i < wordsByAyah.length; i++) {
      final ayahId = baseAyahId + i;
      for (var p = 0; p < wordsByAyah[i].length; p++) {
        final arabic = wordsByAyah[i][p];
        final meta = _wordMeta[arabic];
        out.add(
          WordsCompanion.insert(
            ayahId: ayahId,
            position: p,
            arabic: arabic,
            normalized: arabic, // без отдельной нормализации в MVP
            translation: Value(meta?.translation),
            lemma: Value(meta?.lemma),
            root: Value(meta?.root),
          ),
        );
      }
    }
    return out;
  }

  /// Сгенерировать списки companions таймингов. PK-ids проставит autoIncrement.
  /// [baseAyahId] — id первого аята суры 1 в БД (глобальный 1..6236).
  /// [wordsBaseId] — id первой вставленной word-строки (нужен, потому что
  /// autoIncrement уже сработал и мы знаем диапазон).
  static List<WordTimingsCompanion> buildTimings({
    required int baseAyahId,
    required int wordsBaseId,
  }) {
    final list = <WordTimingsCompanion>[];
    var globalIdx = 0;
    for (var i = 0; i < wordsByAyah.length; i++) {
      for (var p = 0; p < wordsByAyah[i].length; p++) {
        final wordId = wordsBaseId + globalIdx;
        final tt = _t[i][p];
        list.add(
          WordTimingsCompanion.insert(
            wordId: wordId,
            reciterId: 'ar.alafasy',
            startMs: tt[0],
            endMs: tt[1],
          ),
        );
        globalIdx++;
      }
    }
    return list;
  }
}

/// Per-word mushaf metadata for the Al-Fatiha hardcoded seed.
/// Stores transliteration + English translation + Arabic lemma
/// + Arabic root. Used as the value type for
/// [AlFatihaSeed._wordMeta] and as the source of truth for the
/// "Same root" learning card on surah 1.
class _WordMetaEntry {
  const _WordMetaEntry({
    required this.transliteration,
    required this.translation,
    required this.lemma,
    required this.root,
  });

  final String transliteration;
  final String translation;
  final String lemma;
  final String root;
}
