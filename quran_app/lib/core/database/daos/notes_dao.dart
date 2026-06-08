import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'notes_dao.g.dart';

/// Заметки пользователя, привязанные к конкретному аяту.
///
/// Заметки — это free-form текст (размышления, перекрёстные ссылки,
/// закладки для преподавателя). Один аят может иметь несколько заметок
/// (в отличие от [Bookmarks], который per-ayah уникален).
@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  /// Все заметки, упорядоченные по давности редактирования (свежие сверху).
  Stream<List<Note>> watchAll() => (select(notes)
        ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
      .watch();

  /// Заметки одного аята. У одного аята может быть несколько заметок.
  Stream<List<Note>> watchForAyah(int ayahId) =>
      (select(notes)..where((n) => n.ayahId.equals(ayahId)))
          .watch();

  /// Создать новую заметку. Возвращает id.
  Future<int> addNote({
    required int ayahId,
    required String text,
  }) {
    return into(notes).insert(
      NotesCompanion.insert(
        ayahId: ayahId,
        textValue: text,
      ),
    );
  }

  /// Обновить текст существующей заметки. `updatedAt` выставляется
  /// автоматически через Drift.
  Future<int> updateText(Note note, String newText) {
    return (update(notes)..where((n) => n.id.equals(note.id))).write(
      NotesCompanion(
        textValue: Value(newText),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Удалить одну заметку.
  Future<int> deleteById(int id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();

  /// Удалить все заметки для аята (например, при очистке истории чтения).
  Future<int> deleteByAyah(int ayahId) =>
      (delete(notes)..where((n) => n.ayahId.equals(ayahId))).go();

  /// Количество заметок у аята. Реализовано через `watchForAyah().length`,
  /// потому что `countAll` не возвращает Stream — для маленьких списков
  /// (десятки заметок на аят) это OK; для масштабирования можно
  /// переписать через `tableUpdates(TableUpdateQuery.onTable(notes))`.
  Stream<int> watchCountForAyah(int ayahId) {
    return watchForAyah(ayahId).map((rows) => rows.length);
  }
}
