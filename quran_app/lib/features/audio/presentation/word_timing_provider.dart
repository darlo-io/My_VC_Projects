import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/daos/word_timings_dao.dart';
import '../data/audio_player_controller.dart';

/// Тайминги слов текущей проигрываемой суры для текущего ректора.
/// Подгружаются лениво при смене (surah, reciter).
final wordTimingsForCurrentSurahProvider =
    FutureProvider.autoDispose<List<WordTimingRow>>((ref) async {
  final state = ref.watch(audioPlayerControllerProvider);
  final surah = state.surah;
  final reciter = state.reciter;
  if (surah == null || reciter == null) return const [];
  return ref.watch(wordTimingsDaoProvider).getForSurah(
        surahId: surah.id,
        reciterId: reciter.id,
      );
});

/// Индекс текущего слова, основанный на позиции аудио-плеера.
/// -1 = до первого слова (например, в самом начале).
/// -2 = после последнего слова.
class CurrentWordIndex {
  const CurrentWordIndex(this.value);
  final int value;
}

final currentWordIndexProvider = Provider.autoDispose<CurrentWordIndex>((ref) {
  final state = ref.watch(audioPlayerControllerProvider);
  if (!state.playing && !state.loading) {
    return const CurrentWordIndex(-1);
  }
  final pos = state.positionMs;
  final timings = ref.watch(wordTimingsForCurrentSurahProvider).value ?? const [];
  if (timings.isEmpty) return const CurrentWordIndex(-1);

  // Бинарный поиск по startMs.
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
      return CurrentWordIndex(t.wordId);
    }
  }
  if (pos < timings.first.startMs) return const CurrentWordIndex(-1);
  return const CurrentWordIndex(-2);
});

/// Seek to a specific word in the currently loaded audio. Returns true on success.
Future<void> seekToWord(WidgetRef ref, int wordId) async {
  final timings = ref.read(wordTimingsForCurrentSurahProvider).value;
  if (timings == null) return;
  final hit = timings.firstWhere(
    (t) => t.wordId == wordId,
    orElse: () => const WordTimingRow(wordId: 0, startMs: 0, endMs: 0),
  );
  if (hit.wordId == 0) return;
  await ref
      .read(audioPlayerControllerProvider.notifier)
      .seekTo(Duration(milliseconds: hit.startMs));
}
