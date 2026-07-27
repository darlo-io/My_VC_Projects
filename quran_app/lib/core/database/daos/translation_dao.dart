import 'package:drift/drift.dart';

import '../../search/fts_query.dart';
import '../app_database.dart';
import '../models/search_hits.dart';
import '../tables.dart';

part 'translation_dao.g.dart';

class TranslationRow {
  const TranslationRow({
    required this.ayahId,
    required this.text,
  });

  final int ayahId;
  final String text;
}

@DriftAccessor(tables: [Translations, Translators, Ayahs, Surahs])
class TranslationDao extends DatabaseAccessor<AppDatabase>
    with _$TranslationDaoMixin {
  TranslationDao(super.db);

  /// Возвращает перевод конкретного аята на конкретном языке, или
  /// `null` если перевода нет. Используется в [_AyahPanel] для
  /// маленького субтитра под арабским аятом.
  Future<String?> getForAyah({
    required int ayahId,
    required String languageCode,
  }) async {
    final rows = await customSelect(
      '''
      SELECT t.text AS text
      FROM translations t
      INNER JOIN translators tr ON tr.id = t.translator_id
      WHERE t.ayah_id = ? AND tr.language_code = ?
      LIMIT 1
      ''',
      variables: [Variable.withInt(ayahId), Variable.withString(languageCode)],
      readsFrom: {translations, translators},
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.read<String>('text');
  }

  /// Round 8: возвращает перевод аята для конкретного translator'a.
  /// Используется в Reader (reader_screen) после выбора
  /// `activeTranslatorId` — возвращает перевод именно этого
  /// translator'a (а не «первого попавшегося с нужным language_code»).
  /// `null` если перевод ещё не загружен.
  Future<String?> getForAyahByTranslator({
    required int ayahId,
    required int translatorId,
  }) async {
    final rows = await customSelect(
      '''
      SELECT t.text AS text
      FROM translations t
      WHERE t.ayah_id = ? AND t.translator_id = ?
      LIMIT 1
      ''',
      variables: [Variable.withInt(ayahId), Variable.withInt(translatorId)],
      readsFrom: {translations},
    ).get();
    if (rows.isEmpty) return null;
    return rows.first.read<String>('text');
  }

  /// Возвращает переводы аятов конкретной суры на конкретном языке.
  Future<List<TranslationRow>> getForSurah({
    required int surahId,
    required String languageCode,
  }) async {
    final rows = await customSelect(
      '''
      SELECT t.ayah_id AS ayah_id, t.text AS text
      FROM translations t
      INNER JOIN translators tr ON tr.id = t.translator_id
      INNER JOIN ayahs a ON a.id = t.ayah_id
      WHERE a.surah_id = ? AND tr.language_code = ?
      ORDER BY a.ayah_number
      ''',
      variables: [Variable.withInt(surahId), Variable.withString(languageCode)],
      readsFrom: {translations, translators, ayahs},
    ).get();
    return rows
        .map(
          (r) => TranslationRow(
            ayahId: r.read<int>('ayah_id'),
            text: r.read<String>('text'),
          ),
        )
        .toList();
  }

  /// Round 8: переводы аятов суры для конкретного translator'a.
  /// Используется после переключения `activeTranslatorId` — берёт
  /// translations именно этого translator'а (а не «первого с нужным
  /// language_code»). Возвращает пустой список если translations
  /// ещё не загружены (lazy fetch в процессе).
  Future<List<TranslationRow>> getForSurahByTranslator({
    required int surahId,
    required int translatorId,
  }) async {
    final rows = await customSelect(
      '''
      SELECT t.ayah_id AS ayah_id, t.text AS text
      FROM translations t
      INNER JOIN ayahs a ON a.id = t.ayah_id
      WHERE a.surah_id = ? AND t.translator_id = ?
      ORDER BY a.ayah_number
      ''',
      variables: [Variable.withInt(surahId), Variable.withInt(translatorId)],
      readsFrom: {translations, ayahs},
    ).get();
    return rows
        .map(
          (r) => TranslationRow(
            ayahId: r.read<int>('ayah_id'),
            text: r.read<String>('text'),
          ),
        )
        .toList();
  }

  /// Full-text search over translated ayah text using the FTS5 shadow
  /// table `translations_fts`, restricted to translators in
  /// [languageCode] (e.g. `'en'`, `'ru'`).
  ///
  /// Mirrors [AyahDao.searchByText]: empty/invalid queries return
  /// `const []`. Results are ordered by FTS5 rank with surah/ayah
  /// as the tie-breaker.
  Future<List<TranslationSearchHit>> search({
    required String query,
    required String languageCode,
    int limit = 50,
  }) async {
    final ftsQuery = buildFtsPrefixQuery(query);
    if (ftsQuery.isEmpty) return const [];
    final rows = await customSelect(
      '''
      SELECT a.id AS ayah_id,
             a.surah_id AS surah_id,
             a.ayah_number AS ayah_number,
             s.name_ar AS surah_name_ar,
             t.text AS text,
             tr.name AS translator_name
      FROM translations_fts
      INNER JOIN translations t ON t.id = translations_fts.rowid
      INNER JOIN translators tr ON tr.id = t.translator_id
      INNER JOIN ayahs a ON a.id = t.ayah_id
      INNER JOIN surahs s ON s.id = a.surah_id
      WHERE translations_fts MATCH ?
        AND tr.language_code = ?
      ORDER BY rank, a.surah_id, a.ayah_number
      LIMIT ?
      ''',
      variables: [
        Variable.withString(ftsQuery),
        Variable.withString(languageCode),
        Variable.withInt(limit),
      ],
      readsFrom: {translations},
    ).get();
    return rows
        .map(
          (r) => TranslationSearchHit(
            ayahId: r.read<int>('ayah_id'),
            surahId: r.read<int>('surah_id'),
            ayahNumber: r.read<int>('ayah_number'),
            surahNameAr: r.read<String>('surah_name_ar'),
            text: r.read<String>('text'),
            translatorName: r.read<String>('translator_name'),
          ),
        )
        .toList();
  }

  Future<void> insertTranslators(List<TranslatorsCompanion> items) async {
    await batch((b) => b.insertAllOnConflictUpdate(translators, items));
  }

  /// Round 8: bulk-insert переводов для конкретного translator'a
  /// (например, после lazy fetch через Quran.com API).
  /// Используется QuranTranslationSyncService для одного запроса
  /// `/quran/translations/{id}?chapter_number={N}` → 6236 аятов.
  Future<void> bulkInsertForTranslator({
    required int translatorId,
    required List<({int ayahId, String text})> items,
  }) async {
    final companions = items
        .map(
          (it) => TranslationsCompanion.insert(
            ayahId: it.ayahId,
            translatorId: translatorId,
            languageCode: '', // legacy: redundant с translator join
            textValue: it.text,
          ),
        )
        .toList();
    await batch(
      (b) => b.insertAllOnConflictUpdate(translations, companions),
    );
  }

  /// Round 8: сколько translations уже в БД для этого translator'a?
  /// Используется в QuranTranslationSyncService чтобы определить,
  /// нужен ли lazy fetch. >0 = уже синхронизирован.
  Future<int> countForTranslator(int translatorId) async {
    final countExpr = translations.id.count();
    final row = await (selectOnly(translations)
          ..addColumns([countExpr])
          ..where(translations.translatorId.equals(translatorId)))
        .getSingle();
    return row.read<int>(countExpr) ?? 0;
  }

  /// Insert single translator (для Round 8 — добавляем новых
  /// Quran.com translators которых нет в alquran.cloud seed).
  Future<void> insertTranslator(TranslatorsCompanion item) async {
    await into(translators).insertOnConflictUpdate(item);
  }

  /// Round 8: lookup translator по Quran.com id.
  /// Возвращает `null` если не найден (translator ещё не в БД).
  Future<Translator?> findByQuranComId(int quranComId) async {
    if (quranComId <= 0) return null;
    return (select(translators)
          ..where((t) => t.quranComId.equals(quranComId)))
        .getSingleOrNull();
  }

  /// Round 8: все translators для UI выбора (список в Settings).
  /// Отсортированы: сначала русские, потом по nameRu/name.
  Future<List<Translator>> getAllTranslatorsOrdered() async {
    final all = await select(translators).get();
    all.sort((a, b) {
      // Russian first
      final aRu = a.languageCode == 'ru' ? 0 : 1;
      final bRu = b.languageCode == 'ru' ? 0 : 1;
      if (aRu != bRu) return aRu.compareTo(bRu);
      // Then by nameRu if present, else name
      final aName = a.nameRu ?? a.name;
      final bName = b.nameRu ?? b.name;
      return aName.compareTo(bName);
    });
    return all;
  }

  Future<void> insertTranslations(List<TranslationsCompanion> items) async {
    await batch((b) => b.insertAllOnConflictUpdate(translations, items));
  }
}
