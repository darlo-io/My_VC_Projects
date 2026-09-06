import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/database/daos/words_dao.dart';

/// In-memory тест [WordsDao.getBySurah] — одного запроса слов на суру,
/// который заменил N пер-аят запросов в Reader'е (фаза B3
/// оптимизации UI-производительности).
void main() {
  late AppDatabase db;
  late WordsDao wordsDao;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    wordsDao = db.wordsDao;
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedTwoSurahs() async {
    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
            id: const Value(1),
            nameAr: 'الفاتحة',
            nameEn: 'The Opening',
            nameTransliteration: 'Al-Fatiha',
            revelationType: 'Meccan',
            ayahCount: 7,
            orderInMushaf: 1,
          ),
        );
    await db.into(db.surahs).insert(
          SurahsCompanion.insert(
            id: const Value(2),
            nameAr: 'البقرة',
            nameEn: 'The Cow',
            nameTransliteration: 'Al-Baqarah',
            revelationType: 'Medinan',
            ayahCount: 286,
            orderInMushaf: 2,
          ),
        );
    // Аяты суры 1 (id 1..2) и суры 2 (id 3).
    await db.into(db.ayahs).insert(
          AyahsCompanion.insert(
            id: const Value(1),
            surahId: 1,
            ayahNumber: 1,
            textUthmani: 'بِسْمِ ٱللَّهِ',
            textNormalized: 'بسم الله',
          ),
        );
    await db.into(db.ayahs).insert(
          AyahsCompanion.insert(
            id: const Value(2),
            surahId: 1,
            ayahNumber: 2,
            textUthmani: 'ٱلْحَمْدُ لِلَّهِ',
            textNormalized: 'الحمد لله',
          ),
        );
    await db.into(db.ayahs).insert(
          AyahsCompanion.insert(
            id: const Value(3),
            surahId: 2,
            ayahNumber: 1,
            textUthmani: 'الٓمٓ',
            textNormalized: 'الم',
          ),
        );
    // Слова вставляются в нарушенном порядке, чтобы проверить
    // orderBy (ayah_number, position) в запросе.
    Future<void> word(int id, int ayahId, int position, String ar) =>
        db.into(db.words).insert(
              WordsCompanion.insert(
                id: Value(id),
                ayahId: ayahId,
                position: position,
                arabic: ar,
                normalized: ar,
              ),
            );
    await word(5, 2, 1, 'لِلَّهِ');
    await word(3, 2, 2, 'خ');
    await word(1, 1, 2, 'ٱللَّهَ');
    await word(2, 1, 1, 'بِسْمِ');
    await word(4, 3, 1, 'الٓمٓ');
  }

  test('returns only words of the requested surah', () async {
    await seedTwoSurahs();
    final got = await wordsDao.getBySurah(1);
    expect(got.map((w) => w.id).toSet(), {1, 2, 3, 5});
    expect(got.map((w) => w.ayahId).toSet(), {1, 2});
  });

  test('orders by (ayah_number, position) regardless of insert order',
      () async {
    await seedTwoSurahs();
    final got = await wordsDao.getBySurah(1);
    expect(got.map((w) => w.id).toList(), [2, 1, 5, 3]);
  });

  test('empty list for unknown surah', () async {
    await seedTwoSurahs();
    expect(await wordsDao.getBySurah(99), isEmpty);
  });

  test('surah 2 isolated from surah 1', () async {
    await seedTwoSurahs();
    final got = await wordsDao.getBySurah(2);
    expect(got.map((w) => w.id).toList(), [4]);
  });
}
