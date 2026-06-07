import 'dart:async';

import 'package:drift/drift.dart';

import '../../features/audio/data/reciters_repository.dart';
import '../database/app_database.dart';
import '../database/daos/ayah_dao.dart';
import '../database/daos/surah_dao.dart';
import '../database/daos/translation_dao.dart';
import '../search/arabic_normalizer.dart';
import 'content_manifest.dart';

class ContentBootstrapper {
  ContentBootstrapper({
    required this.db,
    required this.surahDao,
    required this.ayahDao,
    required this.translationDao,
    required this.downloader,
    required this.manifestRepository,
    required this.recitersRepository,
  });

  final AppDatabase db;
  final SurahDao surahDao;
  final AyahDao ayahDao;
  final TranslationDao translationDao;
  final ContentDownloader downloader;
  final ContentManifestRepository manifestRepository;
  final RecitersRepository recitersRepository;

  /// Возвращает true, если контент уже загружен.
  Future<bool> isReady() async {
    final s = await surahDao.count();
    final a = await ayahDao.count();
    return s >= 114 && a >= 6236;
  }

  /// Скачать и записать контент в БД. No-op, если уже загружено.
  /// Возвращает true, если контент применён.
  Future<bool> bootstrap() async {
    if (await isReady()) {
      // Контент уже залит — пропускаем дорогую сетевую фазу.
      return true;
    }

    final result = await downloader.downloadAll();
    final manifest = defaultManifest();

    // 1) Сурs — одна короткая транзакция, освобождающая reader-стримы.
    await db.transaction(() async {
      await surahDao.insertAll(
        result.surahs
            .map(
              (s) => SurahsCompanion.insert(
                id: Value(s['number'] as int),
                nameAr: s['name'] as String,
                nameEn: (s['englishName'] as String?) ?? '',
                nameTransliteration:
                    (s['englishNameTranslation'] as String?) ?? '',
                revelationType: (s['revelationType'] as String?) ?? '',
                ayahCount: s['numberOfAyahs'] as int,
                orderInMushaf: s['number'] as int,
              ),
            )
            .toList(),
      );
    });

    // 2) Аяты — отдельная транзакция, чтобы не держать lock на всё.
    await db.transaction(() async {
      await ayahDao.insertAyahs(
        result.ayahs
            .map(
              (a) => AyahsCompanion.insert(
                id: Value(a['id'] as int),
                surahId: a['surah_id'] as int,
                ayahNumber: a['ayah_number'] as int,
                textUthmani: a['text_uthmani'] as String,
                textNormalized:
                    ArabicNormalizer.normalize(a['text_uthmani'] as String),
                page: Value(a['page'] as int?),
                juz: Value(a['juz'] as int?),
                hizb: Value(a['hizb'] as int?),
              ),
            )
            .toList(),
      );
    });

    // 3) Переводчики + переводы — финальная транзакция.
    await db.transaction(() async {
      await translationDao.insertTranslators(
        result.translators
            .map(
              (t) => TranslatorsCompanion.insert(
                id: t['id'] as int,
                name: t['name'] as String,
                languageCode: t['language_code'] as String,
                source: t['source'] as String,
              ),
            )
            .toList(),
      );

      await translationDao.insertTranslations(
        result.translations
            .map(
              (t) => TranslationsCompanion.insert(
                ayahId: t['ayah_id'] as int,
                translatorId: t['translator_id'] as int,
                languageCode: t['language_code'] as String,
                textValue: t['text'] as String,
              ),
            )
            .toList(),
      );
    });

    // 4) Сохраняем манифест, чтобы последующие запуски могли свериться
    //    (в будущем — verify hash / min_app_version).
    await manifestRepository.apply(manifest);

    // 5) Seed ректоров — дефолтный список, идемпотентно.
    await recitersRepository.ensureSeeded();

    return true;
  }
}
