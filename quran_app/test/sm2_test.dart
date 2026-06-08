import 'package:test/test.dart';
import 'package:quran_app/features/learning/data/sm2.dart';

/// Unit tests for the SM-2 (SuperMemo 2) spaced-repetition algorithm.
///
/// These run via plain `dart test` (no flutter_tester) and lock in the
/// behavioral contract of the algorithm. Changing the math should
/// require updating these tests on purpose.
void main() {
  final t0 = DateTime.utc(2026, 1, 1);

  group('Sm2.next — quality < 3 (lapse)', () {
    test('quality 0 resets reps, interval=1, ease drops by 0.2', () {
      final s = Sm2.next(
        easeFactor: 2.5,
        intervalDays: 30,
        repetitions: 5,
        quality: 0,
        now: t0,
      );
      expect(s.repetitions, 0);
      expect(s.intervalDays, 1);
      expect(s.easeFactor, closeTo(2.3, 1e-9));
      expect(s.status, 'learning');
      expect(s.nextReviewAt, t0.add(const Duration(days: 1)));
    });

    test('ease factor is clamped to a floor of 1.3', () {
      // After many lapses ease should not go below 1.3.
      var ease = 1.3;
      for (var i = 0; i < 20; i++) {
        final s = Sm2.next(
          easeFactor: ease,
          intervalDays: 1,
          repetitions: 0,
          quality: 0,
          now: t0,
        );
        ease = s.easeFactor;
      }
      expect(ease, 1.3);
    });
  });

  group('Sm2.next — quality 3 (correct with difficulty)', () {
    test('first success: reps=1, interval=1', () {
      final s = Sm2.next(
        easeFactor: 2.5,
        intervalDays: 0,
        repetitions: 0,
        quality: 3,
        now: t0,
      );
      expect(s.repetitions, 1);
      expect(s.intervalDays, 1);
      expect(s.status, 'learning');
    });

    test('second success: reps=2, interval=6', () {
      final s = Sm2.next(
        easeFactor: 2.5,
        intervalDays: 1,
        repetitions: 1,
        quality: 3,
        now: t0,
      );
      expect(s.repetitions, 2);
      expect(s.intervalDays, 6);
      expect(s.status, 'reviewing');
    });
  });

  group('Sm2.next — quality 4 (correct after hesitation)', () {
    test('third success at reps=2: interval = prev * ease, rounded', () {
      final s = Sm2.next(
        easeFactor: 2.5,
        intervalDays: 6,
        repetitions: 2,
        quality: 4,
        now: t0,
      );
      expect(s.repetitions, 3);
      expect(s.intervalDays, 15, reason: 'round(6 * 2.5)');
      expect(s.status, 'reviewing');
    });
  });

  group('Sm2.next — quality 5 (perfect)', () {
    test('quality 5 multiplies interval by 1.3 on top of ease', () {
      final s = Sm2.next(
        easeFactor: 2.5,
        intervalDays: 6,
        repetitions: 2,
        quality: 5,
        now: t0,
      );
      // 6 * 2.5 = 15; 15 * 1.3 = 19.5 -> rounded to 20
      expect(s.intervalDays, 20, reason: 'round(6 * 2.5 * 1.3) = 20');
    });
  });

  group('Sm2.next — mastered transition', () {
    test('reps >= 8 and ease >= 2.5 → mastered', () {
      // Walk a word up to the mastery threshold.
      var ease = 2.5;
      var interval = 1;
      var reps = 0;
      for (var i = 0; i < 9; i++) {
        final s = Sm2.next(
          easeFactor: ease,
          intervalDays: interval,
          repetitions: reps,
          quality: 4,
          now: t0,
        );
        ease = s.easeFactor;
        interval = s.intervalDays;
        reps = s.repetitions;
      }
      expect(reps, greaterThanOrEqualTo(8));
      expect(ease, greaterThanOrEqualTo(2.5));

      final finalState = Sm2.next(
        easeFactor: ease,
        intervalDays: interval,
        repetitions: reps,
        quality: 4,
        now: t0,
      );
      expect(finalState.status, 'mastered');
    });
  });

  group('Sm2.next — assertions', () {
    test('quality out of range asserts', () {
      expect(
        () => Sm2.next(
          easeFactor: 2.5,
          intervalDays: 1,
          repetitions: 1,
          quality: -1,
          now: t0,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => Sm2.next(
          easeFactor: 2.5,
          intervalDays: 1,
          repetitions: 1,
          quality: 6,
          now: t0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
