import '../database/app_database.dart';
import '../database/daos/ayah_dao.dart';
import '../database/daos/position_dao.dart';
import '../database/daos/surah_dao.dart';
import '../database/daos/translation_dao.dart';
import '../database/daos/words_dao.dart';
import '../database/models/last_read_position.dart';
import 'reader_data.dart';

/// Фасад над мульти-DAO чтения (Surah + Ayah + Translation + Position
/// + Words). Виджеты не должны знать о DAOs и о том, какие таблицы
/// нужно задействовать, чтобы открыть страницу суры или прочитать
/// последнюю позицию. Это — единственная точка контакта.
///
/// Раньше виджеты (reader_screen, home, bookmarks) делали
/// `ref.read(xDaoProvider).foo(...)` напрямую — нарушая
/// ARCHITECTURE §4 (UI → Riverpod Providers → Features → Repositories
/// → Local Database). Сейчас же слой Repositories выделен явно.
class QuranRepository {
  QuranRepository({
    required this.surahDao,
    required this.ayahDao,
    required this.translationDao,
    required this.positionDao,
    required this.wordsDao,
  });

  final SurahDao surahDao;
  final AyahDao ayahDao;
  final TranslationDao translationDao;
  final PositionDao positionDao;
  final WordsDao wordsDao;

  // ----- Surah -----

  Future<List<Surah>> getAllSurahs() => surahDao.getAll();
  Stream<List<Surah>> watchAllSurahs() => surahDao.watchAll();
  Future<Surah?> getSurah(int id) => surahDao.getById(id);

  // ----- Ayah -----

  Future<Ayah?> getAyah(int id) => ayahDao.getById(id);
  Future<Ayah?> getAyahBySurahAndNumber(int surahId, int ayahNumber) =>
      ayahDao.getBySurahAndNumber(surahId, ayahNumber);
  Stream<List<Ayah>> watchAyahsForSurah(int surahId) =>
      ayahDao.watchBySurah(surahId);
  Stream<List<Ayah>> watchAyahsForJuz(int juz, {int? limit}) =>
      ayahDao.watchByJuz(juz, limit: limit);
  int juzForAyah(int surahId, int ayahNumber) =>
      ayahDao.juzForAyah(surahId, ayahNumber);

  // ----- Translation -----

  Future<Map<int, String>> translationsForSurah({
    required int surahId,
    required String languageCode,
  }) async {
    final rows = await translationDao.getForSurah(
      surahId: surahId,
      languageCode: languageCode,
    );
    return {for (final r in rows) r.ayahId: r.text};
  }

  // ----- Position (last-read) -----

  /// Подгрузить `surah + translations` для конкретной surah+lang.
  /// Возвращает [ReaderData] с уже смерженными данными — UI не нужно
  /// делать два отдельных FutureProvider'a.
  Future<ReaderData> loadReaderData({
    required int surahId,
    required String translationLang,
  }) async {
    final surah = await surahDao.getById(surahId);
    if (surah == null) return const ReaderData.empty();
    final translations = await translationsForSurah(
      surahId: surahId,
      languageCode: translationLang,
    );
    return ReaderData(surah: surah, translations: translations);
  }

  Stream<LastReadPosition> watchLastReadPosition() =>
      positionDao.watchLastWithSurah();

  Future<void> recordLastRead({required int surahId, required int ayahId}) =>
      positionDao.setLast(surahId: surahId, ayahId: ayahId);

  /// Increment `reading_history` for today + this surah. Atomic UPSERT
  /// per (date, surah_id) — safe to call on every ayah.
  Future<void> recordAyahRead({required int surahId, DateTime? at}) =>
      positionDao.recordReading(
        date: at ?? DateTime.now(),
        surahId: surahId,
        ayahsRead: 1,
      );

  // ----- Words -----

  Future<List<Word>> wordsForAyah(int ayahId) => ayahDao.getWordsForAyah(ayahId);
  Future<List<Word>> wordsForAyahViaWordsDao(int ayahId) =>
      wordsDao.getByAyah(ayahId);

  // ----- Stats / Reading history -----

  Stream<int> watchTotalAyahs() => positionDao.watchTotalAyahs();
  Stream<int> watchStreakDays({DateTime? now}) =>
      positionDao.watchStreakDays(now: now);
}
