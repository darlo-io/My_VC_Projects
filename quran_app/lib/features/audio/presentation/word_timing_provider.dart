import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/daos/word_timings_dao.dart';

/// Тайминги слов текущей проигрываемой суры для текущего ректора + O(1)
/// wordId → startMs-карта для seekToWord().
class SurahTimings {
  const SurahTimings({required this.rows, required this.startByWordId});
  final List<WordTimingRow> rows;
  final Map<int, int> startByWordId;
}

final wordTimingsForCurrentSurahProvider =
    FutureProvider.autoDispose<SurahTimings>((ref) async {
  // Селективная зависимость ТОЛЬКО от surah/reciter. Раньше watch на
  // весь `AudioPlayerState` инвалидировал провайдер на каждый тик
  // позиции → повторный DB-запрос таймингов всей суры десятки раз
  // в секунду. Surah/Reciter — drift-строки со значимым `==`,
  // поэтому `.select` не дёргает провайдер без реальной смены
  // суры/ректора.
  final surah =
      ref.watch(audioPlayerControllerProvider.select((s) => s.surah));
  final reciter =
      ref.watch(audioPlayerControllerProvider.select((s) => s.reciter));
  if (surah == null || reciter == null) {
    return const SurahTimings(rows: [], startByWordId: {});
  }
  final rows = await ref.watch(wordTimingsDaoProvider).getForSurah(
        surahId: surah.id,
        reciterId: reciter.id,
      );
  final map = <int, int>{for (final r in rows) r.wordId: r.startMs};
  return SurahTimings(rows: rows, startByWordId: map);
});

/// Текущее активное слово (по wordId), либо -1/-2 sentinel:
///   -1 — до первого слова (например, в самом начале);
///   -2 — после последнего слова.
class CurrentWordId {
  const CurrentWordId(this.value);
  final int value;
  static const beforeFirst = CurrentWordId(-1);
  static const afterLast = CurrentWordId(-2);

  /// Значимое равенство нужно `Stream.distinct()` в
  /// [currentWordIdProvider]: виджеты получают событие только при
  /// реальной смене слова, а не на каждый тик позиции.
  @override
  bool operator ==(Object other) =>
      other is CurrentWordId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Активное слово — потоковый провайдер поверх точного
/// [AudioPlayerController.positionStream]. Эмитит значение только в
/// момент смены слова (`distinct()`), поэтому 286 `_ArabicTextBody`
/// открытой суры пересобираются 1–3 раза в секунду (на границах
/// слов), а не ~20 раз на каждый тик позиции.
final currentWordIdProvider =
    StreamProvider.autoDispose<CurrentWordId>((ref) async* {
  final playing =
      ref.watch(audioPlayerControllerProvider.select((s) => s.playing));
  if (!playing) {
    yield CurrentWordId.beforeFirst;
    return;
  }
  final timings = await ref.watch(wordTimingsForCurrentSurahProvider.future);
  final rows = timings.rows;
  if (rows.isEmpty) {
    yield CurrentWordId.beforeFirst;
    return;
  }
  final controller = ref.watch(audioPlayerControllerProvider.notifier);
  yield* controller.positionStream
      .map((p) => _wordIdAt(rows, p.inMilliseconds))
      .distinct();
});

/// Бинарный поиск активного слова по `startMs` (контракт: timings
/// отсортированы по `startMs` в пределах одной суры).
CurrentWordId _wordIdAt(List<WordTimingRow> rows, int pos) {
  var lo = 0;
  var hi = rows.length - 1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    final t = rows[mid];
    if (pos < t.startMs) {
      hi = mid - 1;
    } else if (pos >= t.endMs) {
      lo = mid + 1;
    } else {
      return CurrentWordId(t.wordId);
    }
  }
  if (pos < rows.first.startMs) return CurrentWordId.beforeFirst;
  return CurrentWordId.afterLast;
}

/// Seek to a specific word in the currently loaded audio. O(1) lookup.
Future<void> seekToWord(WidgetRef ref, int wordId) async {
  final timings = ref.read(wordTimingsForCurrentSurahProvider).value;
  if (timings == null) return;
  final startMs = timings.startByWordId[wordId];
  if (startMs == null) return;
  await ref
      .read(audioPlayerControllerProvider.notifier)
      .seekTo(Duration(milliseconds: startMs));
}
