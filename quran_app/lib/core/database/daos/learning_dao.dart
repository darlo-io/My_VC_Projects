import 'package:drift/drift.dart';

import '../../../features/learning/data/sm2.dart';
import '../app_database.dart';
import '../tables.dart';

part 'learning_dao.g.dart';

/// SM-2 review quality 0..5 (Anki-совместимая шкала).
/// 0 = total blackout, 3 = correct with serious difficulty,
/// 4 = correct after hesitation, 5 = perfect recall.
typedef ReviewQuality = int;

/// Запись слова в словаре пользователя + рассчитанные параметры SM-2.
class ReviewedWord {
  const ReviewedWord({
    required this.entry,
    required this.word,
  });

  final LearningWord entry;
  final Word word;
}

@DriftAccessor(tables: [LearningWords, Words])
class LearningDao extends DatabaseAccessor<AppDatabase>
    with _$LearningDaoMixin {
  LearningDao(super.db);

  /// Все записи LearningWords со связанными Word (для экрана "Словарь").
  Stream<List<ReviewedWord>> watchAll() {
    final query = select(learningWords).join([
      innerJoin(words, words.id.equalsExp(learningWords.wordId)),
    ])
      ..orderBy([
        OrderingTerm(expression: learningWords.nextReviewAt),
      ]);
    return query.watch().map((rows) => rows
        .map((r) => ReviewedWord(
              entry: r.readTable(learningWords),
              word: r.readTable(words),
            ))
        .toList());
  }

  /// Слова, которые нужно повторить прямо сейчас (nextReviewAt <= now),
  /// упорядоченные по давности. Не возвращает стадию "mastered".
  Stream<List<ReviewedWord>> watchDue({DateTime? now}) {
    final cutoff = now ?? DateTime.now();
    final query = select(learningWords).join([
      innerJoin(words, words.id.equalsExp(learningWords.wordId)),
    ])
      ..where(learningWords.nextReviewAt.isSmallerOrEqualValue(cutoff) &
          learningWords.status.equals('mastered').not())
      ..orderBy([OrderingTerm(expression: learningWords.nextReviewAt)]);
    return query.watch().map((rows) => rows
        .map((r) => ReviewedWord(
              entry: r.readTable(learningWords),
              word: r.readTable(words),
            ))
        .toList());
  }

  /// Добавить слово в словарь (idempotent: повторный вызов для того же
  /// wordId — no-op благодаря UNIQUE(word_id) + `insertOrIgnore`).
  /// Раньше делался `getSingleOrNull` + insert, что создавало race
  /// condition при двух параллельных вызовах.
  Future<void> addWord(int wordId) async {
    await into(learningWords).insert(
      LearningWordsCompanion.insert(
        wordId: wordId,
        status: 'new',
        nextReviewAt: DateTime.now(),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Удалить слово из словаря.
  Future<int> removeWord(int wordId) =>
      (delete(learningWords)..where((l) => l.wordId.equals(wordId))).go();

  /// Список ID слов, уже добавленных в словарь (для быстрой проверки в UI).
  Stream<Set<int>> watchVocabularyIds() {
    final query = select(learningWords)..orderBy([(l) => OrderingTerm.desc(l.id)]);
    return query.watch().map((rows) => rows.map((r) => r.wordId).toSet());
  }

  /// Применить результат повторения (SM-2). Возвращает обновлённую запись.
  ///
  /// Math делегирован [Sm2.next] — pure-Dart, покрыт юнит-тестами.
  Future<LearningWord> recordReview({
    required int wordId,
    required ReviewQuality quality,
    DateTime? now,
  }) async {
    assert(quality >= 0 && quality <= 5, 'quality must be 0..5');
    final ts = now ?? DateTime.now();
    final existing = await (select(learningWords)
          ..where((l) => l.wordId.equals(wordId)))
        .getSingle();
    final next = Sm2.next(
      easeFactor: existing.easeFactor,
      intervalDays: existing.intervalDays,
      repetitions: existing.repetitions,
      quality: quality,
      now: ts,
    );
    await (update(learningWords)
          ..where((l) => l.id.equals(existing.id)))
        .write(LearningWordsCompanion(
          id: Value(existing.id),
          wordId: Value(existing.wordId),
          status: Value(next.status),
          easeFactor: Value(next.easeFactor),
          intervalDays: Value(next.intervalDays),
          repetitions: Value(next.repetitions),
          nextReviewAt: Value(next.nextReviewAt),
          lastReviewAt: Value(ts),
        ));
    return (select(learningWords)..where((l) => l.id.equals(existing.id)))
        .getSingle();
  }
}
