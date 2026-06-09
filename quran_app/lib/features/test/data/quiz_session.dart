import 'dart:math';

/// One multiple-choice question. Carries the four options and the
/// index of the correct one. The text shown to the user is
/// reconstructed by the screen layer (translation in the user's
/// UI locale, or the Arabic fallback).

/// One multiple-choice question. Carries the four options and the
/// index of the correct one. The text shown to the user is
/// reconstructed by the screen layer (translation in the user's
/// UI locale, or the Arabic fallback).
class QuizQuestion {
  const QuizQuestion({
    required this.ayahId,
    required this.surahId,
    required this.ayahNumber,
    required this.options,
    required this.correctIndex,
    required this.translationText,
  });

  final int ayahId;
  final int surahId;
  final int ayahNumber;

  /// Always exactly 4 entries; the correct one is at
  /// [correctIndex]. Order is randomized at session-build time.
  final List<TranslationOption> options;

  /// Index into [options] that is the correct answer. The screen
  /// layer renders the four buttons in [options] order and
  /// compares the tapped index to this value.
  final int correctIndex;

  /// The full text of the correct translation, used to display
  /// after the user answers (so they see what the right answer
  /// was even if they got it wrong). Pre-cached on the question
  /// so the screen doesn't need to look it up again.
  final String translationText;
}

/// One possible answer in a quiz question. We only carry the
/// `text` and the original `ayahId` it belongs to (so the screen
/// can show "this was the ayah #42" if the user wants the
/// context).
class TranslationOption {
  const TranslationOption({
    required this.ayahId,
    required this.surahId,
    required this.ayahNumber,
    required this.text,
  });

  final int ayahId;
  final int surahId;
  final int ayahNumber;
  final String text;
}

/// Outcome of one answered question. The screen uses this to
/// highlight the correct and wrong options and to update the
/// session score.
class QuizAnswer {
  const QuizAnswer({
    required this.question,
    required this.selectedIndex,
  });
  final QuizQuestion question;

  /// Index the user picked, or `null` if they skipped.
  final int? selectedIndex;

  bool get isCorrect => selectedIndex == question.correctIndex;
  bool get wasSkipped => selectedIndex == null;
}

/// A complete quiz: 10 questions, the running score, and the
/// answered-questions log. The screen renders this as a state
/// machine — see [answer] and [next].
class QuizSession {
  QuizSession({
    required List<QuizQuestion> questions,
    int questionCount = _defaultQuestionCount,
  }) : assert(questions.length == questionCount,
            'QuizSession must hold exactly questionCount questions'),
       _questions = questions;

  /// Default number of questions per session. Tuned to fit one
  /// sitting without the user feeling like it's dragging on.
  static const int _defaultQuestionCount = 10;

  final List<QuizQuestion> _questions;
  int _currentIndex = 0;
  final List<QuizAnswer> _answers = [];
  bool _finished = false;

  static const int optionsPerQuestion = 4;

  /// The question the user should see right now, or `null` if the
  /// session is finished.
  QuizQuestion? get currentQuestion {
    if (_finished) return null;
    return _questions[_currentIndex];
  }

  /// All answers the user has given so far, in order.
  List<QuizAnswer> get answers => List.unmodifiable(_answers);

  /// 0-based index of the current question. Always in
  /// `[0, questions.length)`.
  int get currentIndex => _currentIndex;

  /// Total number of questions in this session.
  int get questionCount => _questions.length;

  /// Number of questions the user has answered correctly so far.
  int get correctCount => _answers.where((a) => a.isCorrect).length;

  /// Number of questions answered (correctly + incorrectly). Does
  /// not include skipped questions.
  int get answeredCount => _answers.length;

  /// `true` once the user has answered all questions (or
  /// skipped to the end). The screen renders a results card when
  /// this flips to `true`.
  bool get isFinished => _finished;

  /// Record the user's [selectedIndex] for the current question
  /// and advance to the next one. Passing `null` records a skip.
  /// Returns the recorded [QuizAnswer].
  QuizAnswer answer(int? selectedIndex) {
    final q = _questions[_currentIndex];
    final ans = QuizAnswer(question: q, selectedIndex: selectedIndex);
    _answers.add(ans);
    return ans;
  }

  /// Move to the next question without recording an answer (used
  /// when the screen renders a "skip" affordance). The session
  /// records the skip as a [QuizAnswer] with `selectedIndex: null`
  /// so the answered count is still correct.
  QuizAnswer skip() => answer(null);

  /// Advance the cursor after [answer] / [skip] has been called.
  /// No-op if the session was already finished.
  void next() {
    if (_finished) return;
    if (_currentIndex + 1 >= _questions.length) {
      _finished = true;
      return;
    }
    _currentIndex++;
  }

  /// Reset to a fresh state with the same questions. Used by the
  /// "play again" button on the results card.
  void reset() {
    _currentIndex = 0;
    _answers.clear();
    _finished = false;
  }

  /// Build a [QuizSession] from a pool of [TranslationRow]s and
  /// the matching [Ayah] metadata. Picks [questionCount] random
  /// ayahs (without replacement) and for each one builds 3
  /// distractor options from the same pool, then shuffles the
  /// four options so the correct answer isn't always at index 0.
  ///
  /// The pool must contain at least [optionsPerQuestion]
  /// translation rows or the constructor will throw — the
  /// minimum pool size for a 10-question session is therefore 4,
  /// but in practice we ship 6236 ayahs so this is never a worry
  /// in production. The `minPoolSize` parameter is the only check
  /// and a friendlier exception helps the test suite debug
  /// fixture issues.
  factory QuizSession.fromTranslations({
    required List<TranslationOption> pool,
    int questionCount = _defaultQuestionCount,
    Random? random,
    int minPoolSize = optionsPerQuestion,
  }) {
    if (pool.length < minPoolSize) {
      throw ArgumentError(
        'QuizSession.fromTranslations needs at least '
        '$minPoolSize translation rows; got ${pool.length}.',
      );
    }
    final rng = random ?? Random();
    // Sample distinct question ayahs. We use a partial Fisher-
    // Yates shuffle of the indices rather than a Set because we
    // want a deterministic ordering for the screen.
    final indices = List<int>.generate(pool.length, (i) => i)..shuffle(rng);
    final chosen = indices.take(questionCount).toList();
    final questions = <QuizQuestion>[];
    for (final i in chosen) {
      final correct = pool[i];
      // Build the 3 distractor pool: every other option in the
      // pool, again shuffled. If we have very few translations
      // available, fall back to whatever we can pull.
      final distractorIndices = List<int>.generate(pool.length, (j) => j)
        ..shuffle(rng);
      final distractors = <TranslationOption>[];
      for (final j in distractorIndices) {
        if (j == i) continue;
        if (distractors.length == optionsPerQuestion - 1) break;
        distractors.add(pool[j]);
      }
      final allOptions = [correct, ...distractors]..shuffle(rng);
      final correctIndex = allOptions.indexOf(correct);
      questions.add(QuizQuestion(
        ayahId: correct.ayahId,
        surahId: correct.surahId,
        ayahNumber: correct.ayahNumber,
        options: allOptions,
        correctIndex: correctIndex,
        translationText: correct.text,
      ));
    }
    return QuizSession(
      questions: questions,
      questionCount: questionCount,
    );
  }
}
