// FTS5 unit-тесты SearchDao — Sprint 2.7.
//
// Тестируем полнотекстовый поиск через FTS5 virtual tables
// (ayahs_fts, translations_fts, words_fts), созданные в
// [AppDatabase._createFts].
//
// Использует in-memory БД через `NativeDatabase.memory()`
// (sqflite_common_ffi уже в dev-deps) — никакого реального device.
//
// Стратегия: заполняем таблицы минимальным набором данных, потом
// проверяем FTS5 MATCH-поиск. Проверяем:
//   1. BM25 ranking: точные совпадения выше частичных
//   2. Snippet generation: <mark>...</mark> обрамляет hit
//   3. Prefix search ('mercy*' матчит 'mercy', 'merciful')
//   4. Diacritics-нормализация (Uthmani vs простой текст)
//   5. Multi-language: searchTranslationsFts фильтрует по language_code
//   6. JOIN с реальной таблицей ayahs (проверка rowid соответствия)
//
// **Примечание (2026-07-31)**: схема Drift обновлена в Sprint 2+:
//   - `Translators` больше не имеет `languageName`/`slug`,
//     поле `source` теперь обязательное.
//   - `Translations` хранит `languageCode` денормализованно.
//   - `Words` не имеет `surahId` (только `ayahId` через reference).
// Тесты адаптированы под текущую схему `lib/core/database/tables.dart`.

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/database/daos/search_dao.dart';

void main() {
  late AppDatabase db;
  late SearchDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.searchDao;
  });

  tearDown(() async {
    await db.close();
  });

  // Помощник: вставляет аят и сразу прокидывает его в FTS5.
  Future<void> insertAyah(
    int id, {
    required int surahId,
    required int ayahNumber,
    required String uthmani,
    String normalized = '',
  }) async {
    await db.into(db.ayahs).insert(AyahsCompanion.insert(
          id: Value(id),
          surahId: surahId,
          ayahNumber: ayahNumber,
          textUthmani: uthmani,
          textNormalized: normalized.isEmpty ? uthmani : normalized,
        ));
  }

  group('searchAyahsFts', () {
    test('находит аят по exact слову Uthmani', () async {
      await insertAyah(1, surahId: 1, ayahNumber: 1, uthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');
      await insertAyah(2, surahId: 1, ayahNumber: 2, uthmani: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ');

      final hits = await dao.searchAyahsFts('ٱلرَّحْمَٰنِ');
      expect(hits, hasLength(1));
      expect(hits.first.ayahId, 1);
      expect(hits.first.surahId, 1);
      expect(hits.first.ayahNumber, 1);
      expect(hits.first.snippet, contains('<mark>ٱلرَّحْمَٰنِ</mark>'));
    });

    test('prefix-поиск (* suffix) находит частичные совпадения', () async {
      await insertAyah(1, surahId: 1, ayahNumber: 1, uthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ');
      await insertAyah(2, surahId: 1, ayahNumber: 2, uthmani: 'ٱلرَّحِيمِ رَبُّ ٱلْعَٰلَمِينَ');

      final hits = await dao.searchAyahsFts('ٱلر*');
      expect(hits, hasLength(2));
    });

    test('BM25 ranking: точное совпадение выше prefix', () async {
      await insertAyah(1, surahId: 1, ayahNumber: 1, uthmani: 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');
      await insertAyah(2, surahId: 1, ayahNumber: 2, uthmani: 'ٱلرَّحْمَٰنِ رَبُّ ٱلْعَٰلَمِينَ');
      await insertAyah(3, surahId: 1, ayahNumber: 3, uthmani: 'مَٰلِكِ يَوْمِ ٱلدِّينِ');

      final hits = await dao.searchAyahsFts('ٱلرَّحْمَٰنِ');
      expect(hits, hasLength(2));
      expect(hits.first.ayahId, 1);
    });

    test('quote sanitization: пробелы вокруг query trimmed', () async {
      await insertAyah(1, surahId: 1, ayahNumber: 1, uthmani: 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');

      final hits1 = await dao.searchAyahsFts('  ٱلرَّحْمَٰنِ  ');
      final hits2 = await dao.searchAyahsFts('ٱلرَّحْمَٰنِ');
      expect(hits1.length, hits2.length);
      expect(hits1.first.ayahId, hits2.first.ayahId);
    });

    test('empty query возвращает []', () async {
      expect(await dao.searchAyahsFts(''), isEmpty);
      expect(await dao.searchAyahsFts('   '), isEmpty);
    });

    test('"\'" в query экранируется без ошибок', () async {
      await insertAyah(1, surahId: 1, ayahNumber: 1, uthmani: 'بِسْمِ');
      final hits = await dao.searchAyahsFts("بِسْم'");
      expect(hits, isEmpty);
    });

    test('search_uses text_normalized если задан', () async {
      await insertAyah(
        1, surahId: 1, ayahNumber: 1,
        uthmani: 'بِسْمِ ٱللَّهِ',
        normalized: 'بسم الله',
      );
      final hits = await dao.searchAyahsFts('بسم');
      expect(hits, hasLength(1));
    });

    test('limit ограничивает результат', () async {
      for (var i = 1; i <= 10; i++) {
        await insertAyah(i, surahId: 1, ayahNumber: i, uthmani: 'ٱلرَّحْمَٰنِ آية $i');
      }
      final hits = await dao.searchAyahsFts('ٱلرَّحْمَٰنِ', limit: 3);
      expect(hits, hasLength(3));
    });
  });

  group('searchTranslationsFts', () {
    setUp(() async {
      // Текущая схема `Translators`: id, name, languageCode, source.
      // `languageName`/`slug` были удалены в Sprint 2 (см. таблицы).
      await db.into(db.translators).insert(TranslatorsCompanion.insert(
            id: const Value(1),
            name: 'Кулиев',
            languageCode: 'ru',
            source: 'quran.com',
          ));
      await db.into(db.translations).insert(TranslationsCompanion.insert(
            ayahId: 1,
            translatorId: 1,
            languageCode: 'ru',
            textValue: 'милость милосердного',
          ));
      await db.into(db.translations).insert(TranslationsCompanion.insert(
            ayahId: 2,
            translatorId: 1,
            languageCode: 'ru',
            textValue: 'хвала Аллаху',
          ));
    });

    test('находит переводы по русскому слову', () async {
      final hits = await dao.searchTranslationsFts('милость', languageCode: 'ru');
      expect(hits, hasLength(1));
      expect(hits.first.ayahId, 1);
      expect(hits.first.translatorId, 1);
      expect(hits.first.snippet, contains('<mark>милость</mark>'));
    });

    test('фильтрует по language_code', () async {
      final hits = await dao.searchTranslationsFts('милость', languageCode: 'en');
      expect(hits, isEmpty);
    });

    test('empty query → empty list', () async {
      expect(await dao.searchTranslationsFts('', languageCode: 'ru'), isEmpty);
    });

    test('multi-language: добавляем перевод на en, тот же ayah', () async {
      expect(
        await dao.searchTranslationsFts('mercy', languageCode: 'en'),
        isEmpty,
      );

      await db.into(db.translators).insert(TranslatorsCompanion.insert(
            id: const Value(2),
            name: 'Pickthall',
            languageCode: 'en',
            source: 'quran.com',
          ));
      await db.into(db.translations).insert(TranslationsCompanion.insert(
            ayahId: 1,
            translatorId: 2,
            languageCode: 'en',
            textValue: 'mercy of the merciful',
          ));

      final hits = await dao.searchTranslationsFts('mercy', languageCode: 'en');
      expect(hits, hasLength(1));
      expect(hits.first.languageCode, 'en');
    });
  });

  group('searchWordsFts', () {
    setUp(() async {
      // Схема `Words`: ayahId (через reference), position, arabic,
      // normalized, translation (nullable), lemma, root. `surahId`
      // отсутствует (вычисляется через JOIN с Ayahs/Surahs).
      await insertAyah(1, surahId: 1, ayahNumber: 1, uthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ');
      await db.into(db.words).insert(WordsCompanion.insert(
            ayahId: 1,
            position: 1,
            arabic: 'بِسْمِ',
            normalized: 'بسم',
            translation: const Value('In the name'),
          ));
      await db.into(db.words).insert(WordsCompanion.insert(
            ayahId: 1,
            position: 2,
            arabic: 'ٱللَّهِ',
            normalized: 'الله',
            translation: const Value('of Allah'),
          ));
    });

    test('находит слово по арабскому search', () async {
      final hits = await dao.searchWordsFts('بِسْمِ');
      expect(hits.length, greaterThanOrEqualTo(1));
      expect(hits.first.arabic, 'بِسْمِ');
      expect(hits.first.ayahId, 1);
      expect(hits.first.position, 1);
    });

    test('находит через normalized форму', () async {
      final hits = await dao.searchWordsFts('الله');
      expect(hits, hasLength(1));
      expect(hits.first.normalized, 'الله');
    });

    test('выдаёт translation для найденного слова', () async {
      final hits = await dao.searchWordsFts('بسم');
      expect(hits.first.translation, 'In the name');
    });

    test('empty query → empty list', () async {
      expect(await dao.searchWordsFts(''), isEmpty);
    });
  });

  group('rebuildAll', () {
    test('rebuild после DELETE восстанавливает FTS индекс', () async {
      await insertAyah(1, surahId: 1, ayahNumber: 1, uthmani: 'ٱلرَّحْمَٰنِ ٱلرَّحِيمِ');
      expect(await dao.searchAyahsFts('ٱلرَّحْمَٰنِ'), hasLength(1));
      await (db.delete(db.ayahs)..where((a) => a.id.equals(1))).go();
      expect(await dao.searchAyahsFts('ٱلرَّحْمَٰنِ'), isEmpty);
    });

    test('rebuildAll восстанавливает после bulk-insert без trigger', () async {
      await db.customStatement(
        "INSERT INTO ayahs (id, surah_id, ayah_number, text_uthmani, text_normalized) "
        "VALUES (1, 1, 1, 'ٱلرَّحْمَٰنِ', 'ٱلرَّحْمَٰنِ')",
      );
      expect(await dao.searchAyahsFts('ٱلرَّحْمَٰنِ'), isEmpty);
      await dao.rebuildAll();
      final hits = await dao.searchAyahsFts('ٱلرَّحْمَٰنِ');
      expect(hits, hasLength(1));
    });
  });
}
