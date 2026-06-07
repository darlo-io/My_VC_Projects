/// Чистый data-класс для результата парсинга seed-датасета.
///
/// Вынесен в отдельный файл без Flutter/Dio-зависимостей, чтобы
/// [SeedParser] можно было тестировать через `dart test` без
/// подтягивания всего pub-графа.
class ContentDownloadResult {
  const ContentDownloadResult({
    required this.surahs,
    required this.ayahs,
    required this.translations,
    required this.translators,
  });

  final List<Map<String, dynamic>> surahs;
  final List<Map<String, dynamic>> ayahs;
  final List<Map<String, dynamic>> translations;
  final List<Map<String, dynamic>> translators;
}
