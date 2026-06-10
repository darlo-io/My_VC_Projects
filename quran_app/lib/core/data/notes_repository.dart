import '../database/app_database.dart';
import '../database/daos/notes_dao.dart';

/// Фасад над [NotesDao]. CRUD заметок скрыт за методом с
/// понятными именами, чтобы UI не подбирался к `NotesCompanion`
/// напрямую.
class NotesRepository {
  NotesRepository(this.dao);
  final NotesDao dao;

  Stream<List<Note>> watchForAyah(int ayahId) => dao.watchForAyah(ayahId);
  Stream<int> watchCountForAyah(int ayahId) => dao.watchCountForAyah(ayahId);
  Stream<List<Note>> watchAll() => dao.watchAll();

  Future<int> add({required int ayahId, required String text}) =>
      dao.addNote(ayahId: ayahId, text: text);

  Future<int> update(Note note, String newText) =>
      dao.updateText(note, newText);

  Future<int> deleteById(int id) => dao.deleteById(id);
  Future<int> deleteByAyah(int ayahId) => dao.deleteByAyah(ayahId);
}
