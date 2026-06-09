import 'dart:math';

import 'package:quran_app/features/test/data/quiz_session.dart';
import 'package:test/test.dart';

/// Pure-Dart tests for the quiz-session state machine. The session
/// is fully deterministic given a seeded [Random] so we don't
/// need a database for these — they run under `dart test`.
void main() {
  // Helper: build a pool of 30 fake translation options.
  List<TranslationOption> fakePool({int count = 30}) {
    return List.generate(
      count,
      (i) => TranslationOption(
        ayahId: i + 1,
        surahId: 1,
        ayahNumber: i + 1,
        text: 'translation of ayah ${i + 1}',
      ),
    );
  }

  group('QuizSession.fromTranslations', () {
    test('throws when the pool is too small', () {
      expect(
        () => QuizSession.fromTranslations(pool: fakePool(count: 3)),
        throwsArgumentError,
      );
    });

    test('builds exactly questionCount questions, each with 4 options',
        () {
      final session = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(42),
      );
      expect(session.questionCount, 10);
      for (var i = 0; i < session.questionCount; i++) {
        final q = session.currentQuestion;
        expect(q, isNotNull, reason: 'question $i should not be null');
        expect(q!.options, hasLength(4));
      }
    });

    test('the correct answer is always present in the options list',
        () {
      final session = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(7),
      );
      // Walk all 10 questions and verify the correctIndex is
      // always in range and the option at that index carries the
      // correct ayah metadata.
      for (var i = 0; i < session.questionCount; i++) {
        final q = session.currentQuestion!;
        expect(q.correctIndex, inInclusiveRange(0, 3));
        final correct = q.options[q.correctIndex];
        expect(correct.ayahId, q.ayahId);
        expect(correct.ayahNumber, q.ayahNumber);
        expect(correct.text, q.translationText);
        if (i < session.questionCount - 1) {
          session.answer(null);
          session.next();
        }
      }
    });

    test('questions are sampled without replacement', () {
      final session = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(99),
      );
      final ayahIds = <int>{};
      while (session.currentQuestion != null) {
        ayahIds.add(session.currentQuestion!.ayahId);
        session.answer(null);
        session.next();
      }
      // 10 questions, none should share an ayahId.
      expect(ayahIds.length, 10);
    });

    test('factory is deterministic with a seeded Random', () {
      final a = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(123),
      );
      final b = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(123),
      );
      for (var i = 0; i < a.questionCount; i++) {
        final qa = a.currentQuestion!;
        final qb = b.currentQuestion!;
        expect(qa.ayahId, qb.ayahId);
        expect(qa.correctIndex, qb.correctIndex);
        a.answer(null);
        a.next();
        b.answer(null);
        b.next();
      }
    });
  });

  group('QuizSession.answer / next / skip', () {
    test('answer records and advances the cursor', () {
      final session = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(1),
      );
      final firstQ = session.currentQuestion!;
      final ans = session.answer(0);
      expect(ans.question.ayahId, firstQ.ayahId);
      expect(ans.selectedIndex, 0);
      expect(session.answeredCount, 1);
      session.next();
      expect(session.currentIndex, 1);
      expect(session.currentQuestion!.ayahId, isNot(firstQ.ayahId));
    });

    test('isCorrect is true when selectedIndex matches correctIndex',
        () {
      final session = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(1),
      );
      final q = session.currentQuestion!;
      final ans = session.answer(q.correctIndex);
      expect(ans.isCorrect, isTrue);
      expect(ans.wasSkipped, isFalse);
    });

    test('isCorrect is false when selectedIndex differs from correctIndex',
        () {
      final session = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(1),
      );
      final q = session.currentQuestion!;
      final wrong = (q.correctIndex + 1) % 4;
      final ans = session.answer(wrong);
      expect(ans.isCorrect, isFalse);
    });

    test('skip is recorded as a null selectedIndex', () {
      final session = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(1),
      );
      final ans = session.skip();
      expect(ans.wasSkipped, isTrue);
      expect(ans.selectedIndex, isNull);
      expect(session.answeredCount, 1);
      expect(session.correctCount, 0);
    });

    test('correctCount reflects only correct answers', () {
      final session = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(1),
      );
      for (var i = 0; i < 5; i++) {
        final q = session.currentQuestion!;
        // Alternate correct and wrong to land 3 correct, 2 wrong.
        if (i % 2 == 0) {
          session.answer(q.correctIndex);
        } else {
          session.answer((q.correctIndex + 1) % 4);
        }
        session.next();
      }
      expect(session.answeredCount, 5);
      expect(session.correctCount, 3);
    });

    test('isFinished flips to true after the last next()', () {
      final session = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(1),
      );
      for (var i = 0; i < session.questionCount; i++) {
        session.answer(null);
        session.next();
      }
      expect(session.isFinished, isTrue);
      expect(session.currentQuestion, isNull);
    });
  });

  group('QuizSession.reset', () {
    test('resets cursor and answers but keeps the same questions', () {
      final session = QuizSession.fromTranslations(
        pool: fakePool(count: 30),
        random: Random(1),
      );
      final firstQ = session.currentQuestion!;
      session.answer(0);
      session.next();
      session.reset();
      expect(session.currentIndex, 0);
      expect(session.answeredCount, 0);
      expect(session.isFinished, isFalse);
      // Same questions in the same order (we kept the underlying
      // list) so the first question is still first.
      expect(session.currentQuestion!.ayahId, firstQ.ayahId);
    });
  });
}
