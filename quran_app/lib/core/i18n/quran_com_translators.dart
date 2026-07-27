/// Round 8 (2026-07-23): hardcoded словарь русских переводчиков
/// Quran.com API. Используется для `LocalSeedService.ensureSeeded`
/// при initial sync переводов (Round 8 Этап 1) и для `QuranTranslationSyncService`
/// для lazy fetch (Round 8 Этап 3).
///
/// Аналогия `kTafsirRuNames` (Round 3) и `kSurahRuNames` —
/// hardcoded dictionary известных элементов с понятными русскими именами.
///
/// `quranComId` — id в Quran.com API `/resources/translations`.
/// `nameRu` — display name на русском.
/// `slug` — slug для API URLs (`quran/{slug}/...`).
class QuranComRuTranslator {
  const QuranComRuTranslator({
    required this.quranComId,
    required this.nameRu,
    required this.slug,
  });
  final int quranComId;
  final String nameRu;
  final String slug;
}

const List<QuranComRuTranslator> kQuranComRuTranslators = [
  QuranComRuTranslator(quranComId: 45, nameRu: 'Кулиев', slug: 'quran.ru.kuliev'),
  QuranComRuTranslator(quranComId: 78, nameRu: 'Минвакф Египта', slug: 'ru-ministry-of-awqaf'),
  QuranComRuTranslator(quranComId: 79, nameRu: 'Абу Адель', slug: 'ru-abu-adel'),
];

/// **Round 8 helper**: возвращает `nameRu` для Quran.com id
/// переводчика, или `null` если не в нашем списке.
String? ruNameForQuranComId(int quranComId) {
  for (final t in kQuranComRuTranslators) {
    if (t.quranComId == quranComId) return t.nameRu;
  }
  return null;
}

/// **Round 8 helper**: возвращает slug для Quran.com id переводчика.
String? slugForQuranComId(int quranComId) {
  for (final t in kQuranComRuTranslators) {
    if (t.quranComId == quranComId) return t.slug;
  }
  return null;
}
