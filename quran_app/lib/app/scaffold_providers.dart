// Sprint 1.4 scaffold: proof-of-concept для riverpod_generator.
//
// Этот файл НЕ используется в production — только проверяет что
// build_runner + riverpod_generator работают в нашем проекте. После
// Sprint 1 полная миграция providers.dart будет включать конвертацию
// реальных провайдеров (dnsSettingsVersion, reciterState и т.д.)
// с @riverpod-аннотациями.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scaffold_providers.g.dart';

/// Простой Provider с @riverpod-аннотацией.
@riverpod
String scaffoldAppName(Ref ref) => 'quran_app';

/// Async Provider, демонстрирующий FutureProvider.
@riverpod
Future<int> scaffoldSurahCount(Ref ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 100));
  return 114;
}

/// Provider с параметром (family).
@riverpod
String scaffoldSurahName(Ref ref, int surahId) {
  return 'Surah $surahId';
}
