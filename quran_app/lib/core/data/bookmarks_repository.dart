import '../database/app_database.dart';
import '../database/daos/bookmark_dao.dart';

/// Фасад над [BookmarkDao]. Toggle / watch / delete идёт через
/// репозиторий, чтобы UI не лазил в DAO напрямую.
class BookmarksRepository {
  BookmarksRepository(this.dao);
  final BookmarkDao dao;

  Stream<List<Bookmark>> watchAll() => dao.watchAll();
  Stream<Set<int>> watchBookmarkedAyahIds() => dao.watchBookmarkedAyahIds();
  Stream<bool> watchIsBookmarked(int ayahId) => dao.watchIsBookmarked(ayahId);

  /// Идемпотентный toggle. Возвращает `true` если закладка
  /// поставлена, `false` если снята.
  Future<bool> toggle({
    required int surahId,
    required int ayahId,
    required int ayahNumber,
    required bool isCurrentlyBookmarked,
  }) async {
    if (isCurrentlyBookmarked) {
      await dao.deleteByAyah(ayahId);
      return false;
    }
    await dao.insertBookmark(
      BookmarksCompanion.insert(
        surahId: surahId,
        ayahId: ayahId,
        ayahNumber: ayahNumber,
      ),
    );
    return true;
  }
}
