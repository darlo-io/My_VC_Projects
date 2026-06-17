import 'dart:io';

// Find unused localizations in app_en.arb vs lib/**/*.dart usages.
void main(List<String> args) {
  final arbFile = File('lib/l10n/app_en.arb');
  if (!arbFile.existsSync()) {
    print('ERROR: ${arbFile.path} not found');
    exit(1);
  }
  final arbContent = arbFile.readAsStringSync();

  // Parse keys from JSON-like content (simple regex, no need for full parser).
  final keyPattern = RegExp(r'"([a-zA-Z0-9_]+)"\s*:\s*"(?:[^"\\]|\\.)*"');
  final keys = keyPattern.allMatches(arbContent).map((m) => m.group(1)!).toSet();
  print('Found ${keys.length} keys in app_en.arb');

  final libDir = Directory('lib');
  final testDir = Directory('test');
  final dartFiles = <String>[
    ...libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.absolute.path),
    if (testDir.existsSync())
      ...testDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .map((f) => f.absolute.path),
  ];
  print('Scanning ${dartFiles.length} .dart files...');

  // For each key, find usages in dart files via grep-like approach.
  final unused = <String>[];
  final debugKeys = {'cardListen', 'appTitle'};
  for (final key in keys) {
    var found = false;
    var firstMatch = '';
    for (final filePath in dartFiles) {
      final content = File(filePath).readAsStringSync();
      // Строгие шаблоны использования AppLocalizations:
      //   - t.<key>  — обычное использование
      //   - '.<key>' — через строковый литерал (например, в тестах)
      //   - <key>:' — синтаксис конструктора (named param)
      //   - <key>: t. — в JSON-mock-объектах
      //   - ${<key>} — интерполяция
      // Избегаем частичного совпадения (например, 'cancel' в
      // 'cancelAction'): нужны точки/двоеточия/знак доллара вокруг.
      final patterns = [
        RegExp(r'\.' + key + r'(?!\w)'), // t.cancel
        RegExp(r'\.' + key + "'"), // '.cancel'
        RegExp('(?<!\\w)' + key + r'\s*:'), // cancel: (named param)
        // ${cancel} — литеральный $ через \$.
        RegExp('\\\$' + key + r'(?!\w)'),
        RegExp('(?<!\\w)' + key + r'\s*\(\s*\)'), // cancel()
        // AppLocalizations.of(context).cancel — Без `t.` префикса.
        RegExp(r'\b' + key + r'\b'), // любой word-boundary usage
      ];
      for (final p in patterns) {
        final m = p.allMatches(content).toList();
        if (m.isNotEmpty) {
          found = true;
          firstMatch = '$filePath via pattern ${m.first.pattern}';
          break;
        }
      }
      if (found) break;
    }
    if (debugKeys.contains(key)) {
      print('DEBUG: $key → found=$found $firstMatch');
    }
    if (!found) {
      unused.add(key);
    }
  }

  print('\n=== UNUSED KEYS (${unused.length}) ===');
  for (final k in unused.sorted()) {
    print('  $k');
  }
}

extension _ListSort<T> on List<T> {
  List<T> sorted() {
    final copy = List<T>.from(this);
    copy.sort();
    return copy;
  }
}