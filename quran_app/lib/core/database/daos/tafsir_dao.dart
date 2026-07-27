import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'tafsir_dao.g.dart';

@DriftAccessor(tables: [TafsirSources, Tafsirs])
class TafsirDao extends DatabaseAccessor<AppDatabase> with _$TafsirDaoMixin {
  TafsirDao(super.db);

  /// Все источники тафсиров, опционально фильтрованные по language_code
  /// (например 'ru', 'ar', 'en'). Используется в UI picker'е и при
  /// выборе default-source для текущего UI-языка.
  Future<List<TafsirSource>> getAllSources({String? languageCode}) {
    final q = select(tafsirSources);
    if (languageCode != null) {
      q.where((s) => s.languageCode.equals(languageCode));
    }
    q.orderBy([(s) => OrderingTerm.asc(s.nameEn)]);
    return q.get();
  }

  /// Reactive список для live-обновления UI (например, после
  /// [TafsirsSyncService.syncFromApi]). Возвращает ВСЕ источники;
  /// фильтрацию по языку делает UI.
  Stream<List<TafsirSource>> watchAllSources() =>
      (select(tafsirSources)
            ..orderBy([(s) => OrderingTerm.asc(s.nameEn)]))
          .watch();

  /// Reactive список по языку.
  Stream<List<TafsirSource>> watchSourcesByLanguage(String languageCode) =>
      (select(tafsirSources)
            ..where((s) => s.languageCode.equals(languageCode))
            ..orderBy([(s) => OrderingTerm.asc(s.nameEn)]))
          .watch();

  Future<TafsirSource?> getById(int id) =>
      (select(tafsirSources)..where((s) => s.id.equals(id)))
          .getSingleOrNull();

  /// Тафсиры для конкретного аята. `sourceId == null` — все источники.
  Future<List<Tafsir>> getForAyah(int ayahId, {int? sourceId}) {
    final q = select(tafsirs)..where((t) => t.ayahId.equals(ayahId));
    if (sourceId != null) {
      q.where((t) => t.tafsirSourceId.equals(sourceId));
    }
    return q.get();
  }

  /// Reactive-вариант для UI: обновляется при записи/обновлении
  /// тафсира в кеш.
  Stream<List<Tafsir>> watchByAyahAndSource(int ayahId, int sourceId) =>
      (select(tafsirs)
            ..where((t) =>
                t.ayahId.equals(ayahId) &
                t.tafsirSourceId.equals(sourceId)))
          .watch();

  /// Insert-or-update источника тафсира. Используется при
  /// [TafsirsSyncService.syncFromApi].
  ///
  /// `nameRu` — nullable: только для русской локали (`languageCode='ru'`)
  /// синк передаёт сюда переведённое имя; для других локалей поле
  /// остаётся null и UI fallback на [TafsirSource.nameEn].
  Future<void> upsertSource({
    required int id,
    required String slug,
    required String nameAr,
    required String nameEn,
    required String languageCode,
    int? quranComId,
    String? nameRu,
  }) async {
    await into(tafsirSources).insertOnConflictUpdate(
      TafsirSourcesCompanion.insert(
        id: Value(id),
        slug: slug,
        nameAr: nameAr,
        nameEn: nameEn,
        nameRu: Value(nameRu),
        languageCode: languageCode,
        quranComId: Value(quranComId),
      ),
    );
  }

  /// Insert-or-update текста тафсира для (ayah, source). В таблице
  /// [Tafsirs] нет UNIQUE(ayahId, tafsirSourceId) (только
  /// autoIncrement `id`), поэтому делаем UPDATE-WHERE-AND-INSERT
  /// pattern: сначала пробуем обновить существующую строку, если
  /// ни одна не задета — вставляем новую.
  Future<void> upsertTafsir({
    required int ayahId,
    required int tafsirSourceId,
    required String text,
  }) async {
    final updated = await (update(tafsirs)
          ..where((t) =>
              t.ayahId.equals(ayahId) &
              t.tafsirSourceId.equals(tafsirSourceId)))
        .write(TafsirsCompanion(textValue: Value(text)));
    if (updated == 0) {
      await into(tafsirs).insert(
        TafsirsCompanion.insert(
          ayahId: ayahId,
          tafsirSourceId: tafsirSourceId,
          textValue: text,
        ),
      );
    }
  }
}
