import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart' show rootBundle;

import '../../features/audio/data/reciters_repository.dart';
import '../../features/quran/data/al_fatiha_seed.dart';
import '../database/app_database.dart';
import '../database/daos/ayah_dao.dart';
import '../database/daos/surah_dao.dart';
import '../database/daos/translation_dao.dart';
import '../database/daos/word_timings_dao.dart';
import '../database/daos/words_dao.dart';
import '../search/arabic_normalizer.dart';
import 'content_manifest.dart';
import 'content_update_service.dart';
import 'local_seed_service.dart';

class ContentBootstrapper {
  ContentBootstrapper({
    required this.db,
    required this.surahDao,
    required this.ayahDao,
    required this.translationDao,
    required this.wordsDao,
    required this.wordTimingsDao,
    required this.downloader,
    required this.manifestRepository,
    required this.recitersRepository,
    required this.localSeed,
  });

  final AppDatabase db;
  final SurahDao surahDao;
  final AyahDao ayahDao;
  final TranslationDao translationDao;
  final WordsDao wordsDao;
  final WordTimingsDao wordTimingsDao;
  final ContentDownloader downloader;
  final ContentManifestRepository manifestRepository;
  final RecitersRepository recitersRepository;
  final LocalSeedService localSeed;

  /// Опциональный [ContentUpdateService] для network-fetch +
  /// verify + apply manifest'а. Передаётся вызывающим (см.
  /// [contentBootstrapperProvider]) — иначе fallback к
  /// `downloader.downloadAll()` без проверки.
  ContentUpdateService? contentUpdateService;

  /// Состояние прогресса для UI.
  final ValueNotifier<BootstrapProgress> progress =
      ValueNotifier(const BootstrapProgress.idle());

  /// Прогресс сетевой загрузки остальных сур (опционально).
  final ValueNotifier<NetworkFetchProgress> networkProgress =
      ValueNotifier(const NetworkFetchProgress.idle());

  /// Возвращает true, если контент уже загружен.
  Future<bool> isReady() async {
    final s = await surahDao.count();
    final a = await ayahDao.count();
    return s >= 114 && a >= 6236;
  }

  /// Загрузить контент. Offline-first: начинает с local seed (5 MB bundle),
  /// затем (опционально) пробует сеть для проверки обновлений.
  /// Возвращает true, если контент применён.
  Future<bool> bootstrap() async {
    if (await isReady()) {
      // Content уже на диске. Дополнительно проверяем SHA256
      // сохранённого payload'а на повреждение — если файл был
      // модифицирован / повреждён вне APK, `appliedPayloadSha256`
      // ≠ `actualSha256` → `rebuild` с нуля.
      if (!await _verifyStoredPayload()) {
        progress.value = const BootstrapProgress.loadingLocal();
        final result = await localSeed.load();
        await _applyLocalSeed(result, payloadSha256: await _sha256OfAsset());
      }
      progress.value = const BootstrapProgress.complete(offline: true);
      return true;
    }

    // 1) Локальный seed — гарантированно, без сети.
    progress.value = const BootstrapProgress.loadingLocal();
    final result = await localSeed.load();
    // SHA256-verification payload'а (см. ARCHITECTURE §16):
    // считаем хеш бандла из APK, и если он не совпадает с
    // ранее сохранённым, считаем что данные повреждены —
    // rollback manifest, и при следующем bootstrap'е пере-применим
    // с нуля (на этом запуске — мы уже в mid-bootstrap, поэтому
    // просто перезатираем).
    final payloadSha256 = await _sha256OfAsset();
    await _applyLocalSeed(result, payloadSha256: payloadSha256);

    progress.value = const BootstrapProgress.complete(offline: true);

    // 2) Сетевой fetch — best-effort, не блокирует UI. Если не получится —
    //    приложение работает на local seed.
    unawaited(_fetchFromNetworkInBackground());

    return true;
  }

  /// SHA256 hex-хеш `assets/quran_seed/quran_full.json` (payload,
  /// который зовётся [LocalSeedService.load]). Вызывается перед
  /// [_applyLocalSeed] — хеш сохраняется в manifest
  /// (`content.manifest.sha256`) и проверяется при следующем
  /// bootstrap'е через [_verifyStoredPayload].
  Future<String> _sha256OfAsset() async {
    final raw = await rootBundle.loadString(localSeed.assetPath);
    final digest = crypto.sha256.convert(utf8.encode(raw));
    return digest.toString();
  }

  /// Сравнивает SHA256, сохранённый в manifest'е после последнего
  /// apply, с SHA256 текущего asset'а. Если не совпадает —
  /// значит, APK переустановили с другим payload'ом, или
  /// bundle был повреждён на диске. В обоих случаях нужен
  /// re-apply.
  Future<bool> _verifyStoredPayload() async {
    final stored = await manifestRepository.appliedPayloadSha256();
    if (stored == null) return true; // ничего не сохранено — не с чем сравнивать
    final actual = await _sha256OfAsset();
    return stored == actual;
  }

  Future<void> _applyLocalSeed(
    ContentDownloadResult result, {
    String? payloadSha256,
  }) async {
    // Один-единственный transaction на весь bootstrap. Если что-то
    // упадёт (например, диск заполнится на 3000-м аяте) — Drift
    // откатит все вставки, и БД останется в pre-bootstrap состоянии.
    // Следующий запуск заново вызовет `_applyLocalSeed` и
    // перезапустит процесс с нуля, не оставив полупосеянную БД.
    //
    // Раньше это были 3 отдельные транзакции + ещё две не-
    // транзакционные записи manifest/reciters/words. Прерывание
    // между ними оставляло БД в inconsistent состоянии.
    await db.transaction(() async {
      await surahDao.insertAll(
        result.surahs
            .map(
              (s) => SurahsCompanion.insert(
                id: Value(s['number'] as int),
                nameAr: (s['name'] as String?) ?? '',
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
      await ayahDao.insertAyahs(
        result.ayahs
            .map(
              (a) => AyahsCompanion.insert(
                id: Value(a['id'] as int),
                surahId: a['surah_id'] as int,
                ayahNumber: a['ayah_number'] as int,
                textUthmani: a['text_uthmani'] as String,
                textNormalized: ArabicNormalizer.normalize(
                  a['text_uthmani'] as String,
                ),
                // page/juz/hizb are intentionally omitted: their
                // default is `Value.absent()` which the column
                // maps to NULL. The post-create `backfillJuzColumn`
                // and `backfillPageAndHizbColumn` migrations then
                // populate the values from the in-tree lookup
                // tables. Passing `Value(null)` here would be a
                // no-op write that the backfills would still
                // have to overwrite — pure overhead.
              ),
            )
            .toList(),
      );
      await translationDao.insertTranslators(
        result.translators
            .map(
              (t) => TranslatorsCompanion.insert(
                id: Value(t['id'] as int),
                name: t['name'] as String,
                languageCode: t['language_code'] as String,
                source: (t['source'] as String?) ?? '',
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

    // Manifest / reciters / words — отдельные мелкие writes.
    // Они либо idempotent (manifest: перезаписывает), либо guarded
    // count-check'ом (`_seedWordsFromResult` / `_seedAlFatihaWords`
    // сначала смотрят `if (count > 0) return`), так что
    // повторный запуск после частичного успеха — no-op.
    await manifestRepository.apply(
      defaultManifest(),
      payloadSha256: payloadSha256,
    );
    await recitersRepository.ensureSeeded();
    await _seedAlFatihaWords();
    await _seedWordsFromResult(result);
  }

  /// Insert the per-word mushaf dictionary from
  /// `assets/quran_seed/words.json` (populated by
  /// `tools/build_words_seed.dart`). Idempotent: a count check
  /// short-circuits the insert if the `words` table is already
  /// populated. We deliberately do *not* merge — re-running the
  /// seed against an existing DB assumes the user has either
  /// wiped or is fine with the old data.
  Future<void> _seedWordsFromResult(ContentDownloadResult result) async {
    if (result.words.isEmpty) return;
    if (await wordsDao.count() > 0) return;
    await wordsDao.insertAll(
      result.words
          .map(
            (w) => WordsCompanion.insert(
              ayahId: w['ayah_id'] as int,
              position: w['position'] as int,
              arabic: w['arabic'] as String,
              // Normalize the Arabic form so the FTS5 prefix
              // search (and the `searchByRoot` LIKE query) both
              // find the row regardless of the spelling variant
              // the user types.
              normalized: w['arabic'] as String,
              translation: Value(w['translation'] as String?),
              lemma: Value(w['lemma'] as String?),
              root: Value(w['root'] as String?),
            ),
          )
          .toList(),
    );
  }

  /// Хардкод-сюр Al-Fatiha: слова + тайминги.
  Future<void> _seedAlFatihaWords() async {
    if (await wordsDao.count() > 0) return;
    const baseAyahId = 1;
    await wordsDao.insertAll(AlFatihaSeed.wordsCompanions(baseAyahId));
    final firstWord = await db.customSelect(
      'SELECT id FROM words WHERE ayah_id = ? ORDER BY id ASC LIMIT 1',
      variables: [Variable.withInt(baseAyahId)],
      readsFrom: {db.words},
    ).getSingleOrNull();
    if (firstWord == null) return;
    final wordsBaseId = firstWord.read<int>('id');
    final timings = AlFatihaSeed.buildTimings(
      baseAyahId: baseAyahId,
      wordsBaseId: wordsBaseId,
    );
    await wordTimingsDao.insertAll(timings);
  }

  /// В фоне: проверка обновлений через сеть. Не критично.
  ///
  /// На MVP v0.1 — просто `downloader.downloadAll()` для прогрева
  /// audio-кеша. В Tier 3-11 — переключаем на
  /// `ContentUpdateService.checkAndApply()`, который скачивает
  /// manifest → SHA256 verify → ED25519 verify → min_app_version →
  /// apply, и только при успехе делает `downloader.downloadAll()`.
  ///
  /// Передаётся [contentUpdateService] через DI (см. bootstrap()
  /// — вызывающий передаёт опциональный сервис). Если `null`
  /// (на свежей установке, где провайдер ещё не инициализирован)
  /// — fallback к `downloader.downloadAll()`.
  Future<void> _fetchFromNetworkInBackground({
    ContentUpdateService? contentUpdateService,
  }) async {
    try {
      networkProgress.value = const NetworkFetchProgress.started();
      if (contentUpdateService != null) {
        await contentUpdateService.checkAndApply();
      } else {
        await downloader.downloadAll();
      }
      networkProgress.value = const NetworkFetchProgress.completed();
    } catch (_) {
      networkProgress.value = const NetworkFetchProgress.failed();
    }
  }
}

class BootstrapProgress {
  const BootstrapProgress._({
    required this.stage,
    required this.message,
    this.progress,
  });

  final String stage;
  final String message;
  final double? progress;

  const BootstrapProgress.idle()
      : this._(stage: 'idle', message: '', progress: null);

  const BootstrapProgress.loadingLocal()
      : this._(stage: 'loadingLocal', message: 'bootstrapDownloading', progress: null);

  const BootstrapProgress.complete({required bool offline})
      : this._(
          stage: 'complete',
          message: offline ? 'localReady' : 'complete',
          progress: 1.0,
        );
}

class NetworkFetchProgress {
  const NetworkFetchProgress._({required this.stage});

  final String stage;
  const NetworkFetchProgress.idle() : this._(stage: 'idle');
  const NetworkFetchProgress.started() : this._(stage: 'started');
  const NetworkFetchProgress.completed() : this._(stage: 'completed');
  const NetworkFetchProgress.failed() : this._(stage: 'failed');
}
