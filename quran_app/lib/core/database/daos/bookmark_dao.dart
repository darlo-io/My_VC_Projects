import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'bookmark_dao.g.dart';

@DriftAccessor(tables: [Bookmarks])
class BookmarkDao extends DatabaseAccessor<AppDatabase> with _$BookmarkDaoMixin {
  BookmarkDao(super.db);

  Stream<List<Bookmark>> watchAll() => (select(bookmarks)
        ..orderBy([(b) => OrderingTerm.desc(b.createdAt)]))
      .watch();

  /// Поток ID аятов, для которых есть закладка. Один поток на весь экран.
  Stream<Set<int>> watchBookmarkedAyahIds() {
    return select(bookmarks).watch().map(
          (rows) => rows.map((r) => r.ayahId).toSet(),
        );
  }

  Stream<bool> watchIsBookmarked(int ayahId) =>
      (select(bookmarks)..where((b) => b.ayahId.equals(ayahId)))
          .watchSingleOrNull()
          .map((e) => e != null);

  Future<int> insertBookmark(BookmarksCompanion b) =>
      into(bookmarks).insert(
        b,
        mode: InsertMode.insertOrIgnore,
      );

  Future<int> deleteByAyah(int ayahId) =>
      (delete(bookmarks)..where((b) => b.ayahId.equals(ayahId))).go();
}
