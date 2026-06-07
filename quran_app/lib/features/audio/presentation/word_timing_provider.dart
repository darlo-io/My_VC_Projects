import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/daos/word_timings_dao.dart';
import '../data/audio_player_controller.dart';

/// Тайминги слов текущей проигрываемой суры для текущего ректора + O(1)
/// wordId → startMs-карта для seekToWord().
class SurahTimings {
  const SurahTimings({required this.rows, required this.startByWordId});
  final List<WordTimingRow> rows;
  final Map<int, int> startByWordId;
}

final wordTimingsForCurrentSurahProvider =
    FutureProvider.autoDispose<SurahTimings>((ref) async {
  final state = ref.watch(audioPlayerControllerProvider);
  final surah = state.surah;
  final reciter = state.reciter;
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
}

final currentWordIdProvider = Provider.autoDispose<CurrentWordId>((ref) {
  final state = ref.watch(audioPlayerControllerProvider);
  if (!state.playing && !state.loading) {
    return CurrentWordId.beforeFirst;
  }
  final pos = state.positionMs;
  final timings = ref.watch(wordTimingsForCurrentSurahProvider).value?.rows
      ?? const [];
  if (timings.isEmpty) return CurrentWordId.beforeFirst;

  // Бинарный поиск по startMs (контракт: timings отсортированы по
  // startMs в пределах одной позиции).
  var lo = 0;
  var hi = timings.length - 1;
  while (lo <= hi) {
    final mid = (lo + hi) >> 1;
    final t = timings[mid];
    if (pos < t.startMs) {
      hi = mid - 1;
    } else if (pos >= t.endMs) {
      lo = mid + 1;
    } else {
      return CurrentWordId(t.wordId);
    }
  }
  if (pos < timings.first.startMs) return CurrentWordId.beforeFirst;
  return CurrentWordId.afterLast;
});

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
