/// Чистая реализация алгоритма SuperMemo 2 (SM-2) для интервального
/// повторения слов.
///
/// Не зависит от Drift / Flutter — тестируется через `dart test` без
/// `flutter_tester`.
///
/// Шкала quality (Anki-совместимая):
///   0 = total blackout
///   1 = incorrect, familiar
///   2 = incorrect, easy to remember
///   3 = correct, serious difficulty
///   4 = correct, hesitation
///   5 = perfect recall
class Sm2State {
  const Sm2State({
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitions,
    required this.status,
    required this.nextReviewAt,
  });

  final double easeFactor;
  final int intervalDays;
  final int repetitions;

  /// 'new' / 'learning' / 'reviewing' / 'mastered'
  final String status;
  final DateTime nextReviewAt;
}

class Sm2 {
  Sm2._();

  /// Применить результат повторения к предыдущему состоянию.
  ///
  /// Формула (SM-2):
  /// - quality < 3: repetitions = 0; intervalDays = 1; easeFactor -= 0.2
  ///   (clamped к >= 1.3)
  /// - quality == 3, reps == 0 → 1: intervalDays = 1
  /// - quality == 3, reps == 1 → 2: intervalDays = 6
  /// - quality >= 3, reps >= 2: intervalDays = prev * easeFactor
  ///   (при quality == 5 — бонус ×1.3)
  /// - status: 'mastered' при repetitions >= 8 && easeFactor >= 2.5,
  ///   иначе 'reviewing' при reps >= 2, иначе 'learning'
  static Sm2State next({
    required double easeFactor,
    required int intervalDays,
    required int repetitions,
    required int quality,
    required DateTime now,
  }) {
    assert(quality >= 0 && quality <= 5, 'quality must be 0..5');
    var ease = easeFactor;
    var interval = intervalDays;
    var reps = repetitions;

    if (quality < 3) {
      reps = 0;
      interval = 1;
      ease = (ease - 0.2).clamp(1.3, 3.0);
    } else {
      reps += 1;
      if (reps == 1) {
        interval = 1;
      } else if (reps == 2) {
        interval = 6;
      } else {
        interval = (interval * ease).round();
        if (quality == 5) {
          interval = (interval * 1.3).round();
        }
      }
    }

    final status = (reps >= 8 && ease >= 2.5)
        ? 'mastered'
        : (reps >= 2 ? 'reviewing' : 'learning');
    final nextReview = now.add(Duration(days: interval));

    return Sm2State(
      easeFactor: ease,
      intervalDays: interval,
      repetitions: reps,
      status: status,
      nextReviewAt: nextReview,
    );
  }
}
