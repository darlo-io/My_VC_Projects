import 'package:drift/drift.dart';

import '../app_database.dart';
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

@DriftAccessor(tables: [Translations, Translators])
class TranslationDao extends DatabaseAccessor<AppDatabase>
    with _$TranslationDaoMixin {
  TranslationDao(super.db);

  /// Возвращает переводы аятов конкретной суры на конкретном языке.
  Future<List<TranslationRow>> getForSurah({
    required int surahId,
    required String languageCode,
  }) async {
    final rows = await customSelect(
      '''
      SELECT t.ayah_id AS ayah_id, t.text_value AS text
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

  Future<void> insertTranslators(List<TranslatorsCompanion> items) async {
    await batch((b) => b.insertAllOnConflictUpdate(translators, items));
  }

  Future<void> insertTranslations(List<TranslationsCompanion> items) async {
    await batch((b) => b.insertAllOnConflictUpdate(translations, items));
  }
}
