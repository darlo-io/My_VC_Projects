import '../database/app_database.dart';
import '../database/daos/learning_dao.dart';
import '../../features/learning/data/sm2.dart';

/// Фасад над [LearningDao]. SM-2 вычисления делегируются [Sm2.next]
/// (pure-Dart, покрыт юнит-тестами), репозиторий только хранит
/// результат.
class LearningRepository {
  LearningRepository(this.dao);
  final LearningDao dao;

  Stream<List<ReviewedWord>> watchDue({DateTime? now}) =>
      dao.watchDue(now: now);
  Stream<List<ReviewedWord>> watchAll() => dao.watchAll();
  Stream<Set<int>> watchVocabularyIds() => dao.watchVocabularyIds();

  Future<void> add(int wordId) => dao.addWord(wordId);
  Future<int> remove(int wordId) => dao.removeWord(wordId);
  Future<LearningWord> recordReview({
    required int wordId,
    required ReviewQuality quality,
    DateTime? now,
  }) =>
      dao.recordReview(wordId: wordId, quality: quality, now: now);
}
