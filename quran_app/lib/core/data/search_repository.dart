// SearchHit-типы живут в [models/search_hits.dart]. Импорт типов
// здесь — для параметров return-типов search-методов. DAOs импортируют
// `app_database.dart`, что в Dart приводит к циклу импорта с
// SearchRepository. Чтобы разорвать цикл, мы НЕ импортируем DAOs
// здесь напрямую — вместо этого SearchRepository принимает четыре
// async-функции через конструктор (см. typedef'ы ниже). Provider
// в `app/providers.dart` собирает их из DAO-методов, поэтому
// SearchRepository остаётся чистым data-слоем без зависимостей
// от DAOs.
import '../database/models/search_hits.dart';

/// Сводный результат поиска по всем режимам (Quran / Translation /
/// Surah / Words). Виджет `search_screen` отображает их секциями.
class SearchResults {
  const SearchResults({
    required this.surahs,
    required this.ayahs,
    required this.translations,
    required this.words,
    this.empty = false,
  });

  final List<SurahSearchHit> surahs;
  final List<AyahSearchHit> ayahs;
  final List<TranslationSearchHit> translations;
  final List<WordSearchHit> words;

  /// `true` если ни одна ветка не дала результата. UI может
  /// показывать «no results» без отдельной проверки.
  final bool empty;

  static const emptyResult = SearchResults(
    surahs: [],
    ayahs: [],
    translations: [],
    words: [],
    empty: true,
  );
}

/// Function shapes — DAOs expose `Future<List<*SearchHit>> search*`
/// methods; we capture them as plain `Function`s so SearchRepository
/// doesn't need to import any DAO. App-side wiring in
/// `app/providers.dart` calls `dao.searchByText.bind(dao)` once.
typedef SurahSearchFn = Future<List<SurahSearchHit>> Function(
    String query, {int limit});
typedef AyahSearchFn = Future<List<AyahSearchHit>> Function(
    String query, {int limit});
typedef TranslationSearchFn = Future<List<TranslationSearchHit>> Function({
  required String query,
  required String languageCode,
  int limit,
});
typedef WordSearchFn = Future<List<WordSearchHit>> Function(
    String query, {int limit});
typedef WordByRootSearchFn = Future<List<WordSearchHit>> Function(
  String root, {
  int limit,
  int? excludeWordId,
});

/// Фасад над FTS5-поисками. Все четыре ветки (ayahs / translations /
/// surahs / words) вызываются параллельно через один async-call, чтобы
/// UI не писал 4 FutureBuilder'a сам.
///
/// Почему callback-инъекция, а не DAOs напрямую: `app_database.dart`
/// импортирует `daos/words_dao.dart` (как `@DriftAccessor`),
/// `words_dao.dart` импортирует `app_database.dart` (для
/// `DatabaseAccessor<AppDatabase>`). Если бы `SearchRepository`
/// тоже импортировал DAOs, получился бы цикл, который
/// [Dart analyzer не вытягивает](https://github.com/dart-lang/sdk/issues/38340)
/// — `SurahDao/AyahDao` резолвятся, `WordsDao` — нет.
///
/// Через callback-инъекцию SearchRepository видит только типы
/// `*SearchHit` из `models/search_hits.dart` (без DAO). Это
/// сохраняет ARCHITECTURE §4 (UI → Riverpod Providers → Repositories
/// → Local Database), но добавляет одно лишнее связующее
/// преобразование в `app/providers.dart` (`.bind`).
class SearchRepository {
  SearchRepository({
    required this.searchSurahsFn,
    required this.searchAyahsFn,
    required this.searchTranslationsFn,
    required this.searchWordsFn,
    required this.searchWordsByRootFn,
  });

  final SurahSearchFn searchSurahsFn;
  final AyahSearchFn searchAyahsFn;
  final TranslationSearchFn searchTranslationsFn;
  final WordSearchFn searchWordsFn;
  final WordByRootSearchFn searchWordsByRootFn;

  /// Поиск «всё сразу». [languageCode] — код локали переводов
  /// (`ru` / `en` / `ar`). Пустой/whitespace-only запрос возвращает
  /// [SearchResults.emptyResult] — UI не должен делать `MATCH ''`
  /// (FTS5-ошибка).
  Future<SearchResults> searchAll({
    required String query,
    required String languageCode,
    int limit = 30,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return SearchResults.emptyResult;
    final results = await Future.wait<Object>([
      searchSurahsFn(q, limit: limit),
      searchAyahsFn(q, limit: limit),
      searchTranslationsFn(
        query: q,
        languageCode: languageCode,
        limit: limit,
      ),
      searchWordsFn(q, limit: limit),
    ]);
    return SearchResults(
      surahs: results[0] as List<SurahSearchHit>,
      ayahs: results[1] as List<AyahSearchHit>,
      translations: results[2] as List<TranslationSearchHit>,
      words: results[3] as List<WordSearchHit>,
    );
  }

  /// Surah-only режим: подсказки в SurahList, не полный поиск.
  Future<List<SurahSearchHit>> searchSurahs(String query, {int limit = 30}) =>
      searchSurahsFn(query, limit: limit);

  /// Quran-text-only режим.
  Future<List<AyahSearchHit>> searchAyahs(String query, {int limit = 30}) =>
      searchAyahsFn(query, limit: limit);

  /// Только translations. Используется all-mode search (ayahs +
  /// translations) — не нужно дёргать surahs/words.
  Future<List<TranslationSearchHit>> searchTranslations({
    required String query,
    required String languageCode,
    int limit = 30,
  }) =>
      searchTranslationsFn(
        query: query,
        languageCode: languageCode,
        limit: limit,
      );

  /// Все слова с тем же корнем (для секции "Other words with the same
  /// root" в WordCard).
  Future<List<WordSearchHit>> searchWordsByRoot({
    required String root,
    required int excludeWordId,
    int limit = 5,
  }) =>
      searchWordsByRootFn(
        root,
        limit: limit,
        excludeWordId: excludeWordId,
      );
}
