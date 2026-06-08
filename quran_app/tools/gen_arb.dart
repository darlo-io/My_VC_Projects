// Standalone ARB generator. Reads seed + dictionaries, writes 3 ARB files
// (en, ru, ar) with surahName1..114 and reciterName<X> keys injected
// at the right place. Idempotent and safe to re-run.
//
// Strategy: instead of substring manipulation, rewrite the file by
// line-iteration. The closing `}` of the original file is replaced
// with `,injected-block\n}`.
import 'dart:convert';
import 'dart:io';

void main() {
  final j = jsonDecode(File('assets/quran_seed/quran_full.json').readAsStringSync())
      as Map<String, dynamic>;
  final surahs = (j['surahs'] as List).cast<Map<String, dynamic>>();

  const ruNames = <int, String>{
    1: 'Аль-Фатиха', 2: 'Аль-Бакара', 3: 'Аль Имран', 4: 'Ан-Ниса',
    5: 'Аль-Маида', 6: 'Аль-Ан\'ам', 7: 'Аль-А\'раф', 8: 'Аль-Анфаль',
    9: 'Ат-Тавба', 10: 'Юнус', 11: 'Худ', 12: 'Юсуф', 13: 'Ар-Ра\'д',
    14: 'Ибрахим', 15: 'Аль-Хиджр', 16: 'Ан-Нахль', 17: 'Аль-Исра',
    18: 'Аль-Кехф', 19: 'Марьям', 20: 'Та Ха', 21: 'Аль-Анбия',
    22: 'Аль-Хаджж', 23: 'Аль-Му\'минун', 24: 'Ан-Нур', 25: 'Аль-Фуркан',
    26: 'Аш-Шу\'ара', 27: 'Ан-Намль', 28: 'Аль-Касас', 29: 'Аль-\'Анкабут',
    30: 'Ар-Рум', 31: 'Лукман', 32: 'Ас-Саджда', 33: 'Аль-Ахзаб',
    34: 'Саба', 35: 'Фатыр', 36: 'Ясин', 37: 'Ас-Саффат', 38: 'Сад',
    39: 'Аз-Зумар', 40: 'Гафир', 41: 'Фуссылат', 42: 'Аш-Шура',
    43: 'Аз-Зухруф', 44: 'Ад-Духан', 45: 'Аль-Джасия', 46: 'Аль-Ахкаф',
    47: 'Мухаммад', 48: 'Аль-Фатх', 49: 'Аль-Худжурат', 50: 'Каф',
    51: 'Аз-Зарият', 52: 'Ат-Тур', 53: 'Ан-Наджм', 54: 'Аль-Камар',
    55: 'Ар-Рахман', 56: 'Аль-Ваки\'а', 57: 'Аль-Хадид', 58: 'Аль-Муджадила',
    59: 'Аль-Хашр', 60: 'Аль-Мумтахана', 61: 'Ас-Сафф', 62: 'Аль-Джуму\'а',
    63: 'Аль-Мунафикун', 64: 'Ат-Тагабун', 65: 'Ат-Талак', 66: 'Ат-Тахрим',
    67: 'Аль-Мульк', 68: 'Аль-Калам', 69: 'Аль-Хакка', 70: 'Аль-Ма\'аридж',
    71: 'Нух', 72: 'Аль-Джинн', 73: 'Аль-Муззаммиль', 74: 'Аль-Муддассир',
    75: 'Аль-Кыяма', 76: 'Аль-Инсан', 77: 'Аль-Мурсалят', 78: 'Ан-Наба',
    79: 'Ан-Нази\'ат', 80: 'Абаса', 81: 'Ат-Таквир', 82: 'Аль-Инфитар',
    83: 'Аль-Мутаффифин', 84: 'Аль-Иншикак', 85: 'Аль-Бурудж',
    86: 'Ат-Тарик', 87: 'Аль-А\'ля', 88: 'Аль-Гашия', 89: 'Аль-Фаджр',
    90: 'Аль-Баляд', 91: 'Аш-Шамс', 92: 'Аль-Ляйль', 93: 'Ад-Духа',
    94: 'Аш-Шарх', 95: 'Ат-Тин', 96: 'Аль-Алак', 97: 'Аль-Кадр',
    98: 'Аль-Баййина', 99: 'Аз-Залзаля', 100: 'Аль-Адийат',
    101: 'Аль-Кари\'а', 102: 'Ат-Такасур', 103: 'Аль-Аср',
    104: 'Аль-Хумаза', 105: 'Аль-Филь', 106: 'Курайш', 107: 'Аль-Ма\'ун',
    108: 'Аль-Кавсар', 109: 'Аль-Кафирун', 110: 'Ан-Наср', 111: 'Аль-Масад',
    112: 'Аль-Ихлас', 113: 'Аль-Фаляк', 114: 'Ан-Нас',
  };

  const enReciters = <String, String>{
    'ar.alafasy': 'Mishary Rashid Alafasy',
    'ar.abdulbasitmurattal': 'Abdul Basit Abdul Samad',
    'ar.husary': 'Mahmud Khalil Al-Husary',
    'ar.minshawi': 'Mohamed Siddiq Al-Minshawi',
    'ar.abdurrahmaansudais': 'Abdul Rahman Al-Sudais',
    'ar.saaborimadina': 'Ali Al-Hudhaify (Saboor)',
    'ar.hudhaify': 'Ali Al-Hudhaify',
    'ar.ahmedajamy': 'Ahmed Al-Ajamy',
  };
  const ruReciters = <String, String>{
    'ar.alafasy': 'Мишари Рашид аль-Афаси',
    'ar.abdulbasitmurattal': 'Абдул-Басит Абд ус-Самад',
    'ar.husary': 'Махмуд Халиль аль-Хусари',
    'ar.minshawi': 'Мухаммад Сиддик аль-Миншави',
    'ar.abdurrahmaansudais': 'Абдур-Рахман ас-Судайс',
    'ar.saaborimadina': 'Али аль-Худхайфи (Сабора)',
    'ar.hudhaify': 'Али аль-Худхайфи',
    'ar.ahmedajamy': 'Ахмад аль-Аджми',
  };
  const arReciters = <String, String>{
    'ar.alafasy': 'مشاري راشد العفاسي',
    'ar.abdulbasitmurattal': 'عبد الباسط عبد الصمد',
    'ar.husary': 'محمود خليل الحصري',
    'ar.minshawi': 'محمد صديق المنشاوي',
    'ar.abdurrahmaansudais': 'عبد الرحمن السديس',
    'ar.saaborimadina': 'علي الحذيفي',
    'ar.hudhaify': 'علي الحذيفي',
    'ar.ahmedajamy': 'أحمد العجمي',
  };

  String _esc(String s) => s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');

  /// Normalize a reciter id (`ar.alafasy`) to a CamelCase ARB key
  /// suffix (`Alafasy`). This gives nicer `l10n.reciterNameAlafasy`
  /// method names in generated code.
  String _reciterKeyFor(String reciterId) {
    final stripped = reciterId.replaceFirst('ar.', '');
    return stripped.isEmpty
        ? stripped
        : stripped[0].toUpperCase() + stripped.substring(1);
  }

  /// Build a JSON block from a list of (key, value) pairs. If
  /// [isLastInFile] is true, the last entry has no trailing comma
  /// (it's the final key in the ARB object). If false, every entry
  /// has a trailing comma because more keys will follow.
  String jsonBlock(
    List<MapEntry<String, String>> entries, {
    required bool isLastInFile,
  }) {
    final buf = StringBuffer();
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final isLastEntry = i == entries.length - 1;
      final needsComma = !(isLastEntry && isLastInFile);
      buf.writeln('  "${e.key}": "${_esc(e.value)}"${needsComma ? ',' : ''}');
    }
    return buf.toString();
  }

  String surahBlockFor(String Function(int) translate) {
    return jsonBlock(
      [
        for (var i = 1; i <= 114; i++)
          MapEntry('surahName$i', translate(i)),
      ],
      isLastInFile: false, // reciter block follows
    );
  }

  String reciterBlockFor(String Function(String) translate) {
    return jsonBlock(
      [
        for (final id in enReciters.keys)
          MapEntry('reciterName${_reciterKeyFor(id)}', translate(id)),
      ],
      isLastInFile: true, // this is the final block before `}`
    );
  }

  /// Inject the surah + reciter block into [arbPath]. Idempotent: if
  /// the file already has `surahName1` (the first surah key), the
  /// function exits silently.
  void inject(String arbPath, String block) {
    final raw = File(arbPath).readAsStringSync().replaceAll('\r\n', '\n');
    if (raw.contains('"surahName1"')) return;
    final lines = raw.split('\n');
    var lastIdx = lines.length - 1;
    while (lastIdx > 0 && lines[lastIdx].trim().isEmpty) {
      lastIdx--;
    }
    if (lines[lastIdx].trim() != '}') {
      throw StateError(
          '$arbPath: expected closing `}` at end, got: ${lines[lastIdx]}');
    }
    var prevIdx = lastIdx - 1;
    while (prevIdx > 0 && lines[prevIdx].trim().isEmpty) {
      prevIdx--;
    }
    final prevLine = lines[prevIdx];
    final needsComma = !prevLine.trimRight().endsWith(',');
    final newLines = <String>[
      ...lines.sublist(0, prevIdx),
      if (needsComma) '${prevLine.trimRight()},' else prevLine,
      block.trimRight(),
      lines[lastIdx],
    ];
    final newContent = newLines.join('\n');
    File(arbPath).writeAsStringSync(newContent);
    print('  injected $arbPath (${newContent.length} chars)');
  }

  // Build blocks
  final enBlock = surahBlockFor((i) => (surahs[i - 1]['name_transliteration'] ?? surahs[i - 1]['name_en'] ?? '') as String) +
      '\n' +
      reciterBlockFor((id) => enReciters[id]!);
  final ruBlock = surahBlockFor((i) => ruNames[i]!) +
      '\n' +
      reciterBlockFor((id) => ruReciters[id]!);
  final arBlock = surahBlockFor((i) => (surahs[i - 1]['name_arabic'] ?? '') as String) +
      '\n' +
      reciterBlockFor((id) => arReciters[id]!);

  inject('lib/l10n/app_en.arb', enBlock);
  inject('lib/l10n/app_ru.arb', ruBlock);
  inject('lib/l10n/app_ar.arb', arBlock);

  print('done');
}
