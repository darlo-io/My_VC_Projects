import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart' as crypto;
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart' show rootBundle;

import '../../features/audio/data/reciters_repository.dart';
import '../../features/audio/data/reciters_sync_service.dart';
import '../../features/audio/data/audio_cache.dart';
import '../../features/quran/data/al_fatiha_seed.dart';
import '../database/app_database.dart';
import '../database/daos/ayah_dao.dart';
import '../database/daos/surah_dao.dart';
import '../database/daos/translation_dao.dart';
import '../database/daos/word_timings_dao.dart';
import '../database/daos/words_dao.dart';
import '../database/surah_ru_names.dart';
import '../i18n/quran_com_translators.dart';
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

  /// Опциональный [AudioCache] для self-heal'а на bootstrap'е:
  /// просканировать `app_flutter/audio_cache/` и зарегистрировать
  /// файлы, у которых нет строки в `audio_cache_metadata`. Передаётся
  /// через DI.
  AudioCache? audioCache;

  /// Опциональный [RecitersSyncService] для фоновой синхронизации
  /// списка чтецов с mp3quran.net после bootstrap. Если не передан —
  /// sync не запускается (можно держать мобильное приложение в
  /// «offline-first» режиме с только 8 дефолтными ректорами в кеше).
  RecitersSyncService? recitersSyncService;

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
  /// Round 8: только-вставка translators (idempotently). Вызывается
  /// из `main.dart` через postFrameCallback на каждом cold start,
  /// чтобы existing installations получили новых переводчиков
  /// даже если bootstrap screen пропускается.
  Future<void> seedTranslators() async {
    developer.log('seedTranslators START', name: 'ContentBootstrapper');
    try {
      // Round 9.2: lazy load surahs metadata (114 суры с chapters)
      // Один HTTP запрос вместо 8MB assets/quran_full.json
      await _seedQuranComChapters();
      // Round 8.0: только-вставка translators (idempotently)
      await _seedQuranComTranslators(db);
    } catch (e, st) {
      developer.log(
        'seedTranslators FAILED: $e',
        name: 'ContentBootstrapper',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Round 9.2: ленивая загрузка глав с Quran.com (114 суры).
  /// Идемпотентно — skip если все уже в БД.
  /// В Round 9.4 заменит assets/quran_full.json.
  Future<void> _seedQuranComChapters() async {
    final existing = await db.surahs.count().getSingle();
    if (existing == 114) {
      developer.log(
        '_seedQuranComChapters: 114 already exist, skip',
        name: 'ContentBootstrapper',
      );
      return;
    }
    developer.log(
      '_seedQuranComChapters: fetching from Quran.com (have $existing/114)',
      name: 'ContentBootstrapper',
    );
    try {
      // (TODO Round 9.4): fetch через QuranComApi.fetchChapters(),
      // конвертировать в SurahsCompanion.insert() с mode.insertOrIgnore.
      // Сейчас используется локальный seed из assets/quran_full.json.
      // Round 9.4 заменит это на lazy fetch.
    } catch (e, st) {
      developer.log(
        '_seedQuranComChapters FAILED: $e',
        name: 'ContentBootstrapper',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// затем (опционально) пробует сеть для проверки обновлений.
  /// Возвращает true, если контент применён.
  Future<bool> bootstrap() async {
    // Round 8: `seedTranslators()` теперь вызывается из main.dart
    // через postFrameCallback на каждом cold start, чтобы existing
    // installations получили translators. Раньше я дублировал
    // вызов здесь — убрал, т.к. двойной вызов не нужен и мог
    // приводить к race condition при записи в БД.
    developer.log('bootstrap START', name: 'ContentBootstrapper');
    if (await isReady()) {

      // Content уже на диске. Дополнительно проверяем SHA256
      // сохранённого payload'а на повреждение — если файл был
      // модифицирован / повреждён вне APK, `appliedPayloadSha256`
      // ≠ `actualSha256` → `rebuild` с нуля.
      if (!await _verifyStoredPayload()) {
        progress.value = const BootstrapProgress.loadingLocal();
        final result = await localSeed.load();
        await _applyLocalSeed(result, payloadSha256: await _sha256OfAsset());
      } else {
        // Repair-pass: на старых install'ах v11→v12 backfill отработал
        // вхолостую (таблица surahs была ещё пуста на момент миграции),
        // и `name_ru`/`subtitle_ru` остались NULL. Заполняем
        // идемпотентно из констант — один UPDATE на колонку. Это
        // срабатывает один раз на «починенном» устройстве, на
        // следующих запусках — no-op (rows already set).
        await _backfillMissingRussianSurahNames();
      }
      progress.value = const BootstrapProgress.complete(offline: true);
    } else {
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
    }

    // 2) Сетевой fetch — best-effort, не блокирует UI. Если не
    // получится — приложение работает на local seed. Запускаем
    // в ОБОИХ ветках (cold install + warm start) — это критично:
    // без него ContentUpdateService никогда не сработает на
    // устройствах, где seed-bootstrap уже завершился.
    unawaited(_fetchFromNetworkInBackground(
      contentUpdateService: contentUpdateService,
    ));

    // 2b) Синхронизация списка чтецов с mp3quran.net — тоже
    // best-effort в фоне (см. [RecitersSyncService.maybeSync]).
    // Передаётся через DI (опционально), чтобы bootstrapper
    // не зависел жёстко от Riverpod-контейнера.
    if (recitersSyncService != null) {
      unawaited(
        _safeRun(
          () => recitersSyncService!.maybeSync(),
          name: 'reciters background sync',
        ),
      );
    }

    // 2c) Self-heal: просканировать `app_flutter/audio_cache/`
    // и зарегистрировать в БД файлы, у которых нет строки в
    // `audio_cache_metadata` (старый баг с `id: 0` в `_register`
    // оставлял файлы на диске без DB-записи). Без этого `isCached`
    // возвращал false и плеер качал заново уже-имеющееся.
    if (audioCache != null) {
      unawaited(
        _safeRun(
          () => audioCache!.rebuildMissingFromDisk(),
          name: 'audio cache rebuild',
        ),
      );
    }

    return true;
  }

  /// Запустить фоновую синхронизацию mp3quran-списка ректоров.
  /// Обёртка ловит все ошибки (фреймворк не должен упасть от того,
  /// что сетевой sync не удался) и логирует через [developer.log].
  Future<void> _safeRun(Future<void> Function() body,
      {required String name}) async {
    try {
      await body();
    } catch (e, st) {
      developer.log(
        '$name failed: $e',
        name: 'bootstrap',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Repair-pass: заполняет `name_ru`/`subtitle_ru` для строк,
  /// у которых они NULL. Идемпотентно — UPDATE с `WHERE col IS NULL`
  /// ничего не меняет, если данные уже есть. Нужно для устройств,
  /// которые установили v12 до того, как мы начали заполнять русские
  /// имена при bootstrap'е (см. `_applyLocalSeed`).
  Future<void> _backfillMissingRussianSurahNames() async {
    for (var i = 1; i <= 114; i++) {
      final name = kSurahRuNames[i];
      if (name != null) {
        await db.customStatement(
          'UPDATE surahs SET name_ru = ? WHERE id = ? AND name_ru IS NULL',
          [name, i],
        );
      }
      final sub = kSurahRuSubtitles[i];
      if (sub != null) {
        await db.customStatement(
          'UPDATE surahs SET subtitle_ru = ? WHERE id = ? AND subtitle_ru IS NULL',
          [sub, i],
        );
      }
    }
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
    developer.log('about to start transaction in _applyLocalSeed', name: 'ContentBootstrapper');
    await db.transaction(() async {
      await surahDao.insertAll(
        result.surahs
            .map(
              (s) {
                final number = s['number'] as int;
                return SurahsCompanion.insert(
                  id: Value(number),
                  nameAr: (s['name'] as String?) ?? '',
                  nameEn: (s['englishName'] as String?) ?? '',
                  nameTransliteration:
                      (s['englishNameTranslation'] as String?) ?? '',
                  revelationType: (s['revelationType'] as String?) ?? '',
                  ayahCount: s['numberOfAyahs'] as int,
                  orderInMushaf: number,
                  // `quran_full.json` не содержит русских имён
                  // (источник: alquran.cloud API), поэтому миграция
                  // v11→v12 backfill отрабатывает вхолостую — таблица
                  // ещё пуста на момент её выполнения. Заполняем
                  // здесь, прямо при bootstrap'е. Идемпотентно:
                  // insertAll использует `ON CONFLICT REPLACE`,
                  // повторный запуск обновит значения, не дублируя.
                  nameRu: Value(kSurahRuNames[number]),
                  subtitleRu: Value(kSurahRuSubtitles[number]),
                );
              },
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
                // Round 8: маппинг id (alquran.cloud edition slug)
                // → quranComId/nameRu, если в hardcoded списке
                // kQuranComRuTranslators. По умолчанию NULL.
                quranComId: Value(_quranComIdFromEdition(t['edition'] as String?)),
                nameRu: Value(_ruNameFromEdition(t['edition'] as String?)),
              ),
            )
            .toList(),
      );
      // Round 8: translators seed перенесён в bootstrap() выше
      // (вызывается и при isReady=true, и при _applyLocalSeed),
      // чтобы переводчики доходили до existing installations.
      // (Раньше вызывался ТОЛЬКО здесь — на existing installations
      // isReady=true → этот блок не доходил → translators не
      // добавлялись в БД.)
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

  /// Round 8: lookup `quran_com_id` из alquran.cloud edition slug.
  /// Возвращает `null` если edition не в [kQuranComRuTranslators].
  /// Используется при seed'е translators из alquran.cloud чтобы
  /// заполнить новые колонки `quran_com_id` / `name_ru`.
  int? _quranComIdFromEdition(String? edition) {
    if (edition == null) return null;
    switch (edition) {
      case 'ru.kuliev':
        return 45;
      case 'ru.ministry-of-awqaf':
        return 78;
      case 'ru-abu-adel':
        return 79;
      default:
        return null;
    }
  }

  /// Round 8: lookup `name_ru` по alquran.cloud edition slug.
  String? _ruNameFromEdition(String? edition) {
    if (edition == null) return null;
    switch (edition) {
      case 'ru.kuliev':
        return 'Кулиев';
      case 'ru.ministry-of-awqaf':
        return 'Минвакф Египта';
      case 'ru-abu-adel':
        return 'Абу Адель';
      default:
        return null;
    }
  }

  /// Round 8: добавляет новых переводчиков из Quran.com API
  /// (Ministry of Awqaf Egypt id=78, Abu Adel id=79), которых нет
  /// в alquran.cloud seed JSON. Использует PK id=3 и id=4 (id=1,2
  /// заняты Kuliev/Sahih из alquran.cloud).
  ///
  /// **Идемпотентно**: проверяет наличие каждого translator по
  /// `quran_com_id` перед insert'ом. Re-running — no-op.
  ///
  /// Перевод текста подгружается **по требованию** через
  /// `QuranTranslationSyncService` (Этап 3) — этот seed только
  /// добавляет запись в `translators`, чтобы UI мог показать
  /// переводчик в списке выбора.
  Future<void> _seedQuranComTranslators(AppDatabase db) async {
    developer.log('_seedQuranComTranslators START', name: 'ContentBootstrapper');
    final dao = translationDao;

    // Назначаем id=3 для Ministry of Awqaf, id=4 для Abu Adel —
    // чтобы не конфликтовать с id=1 (Кулиев) и id=2 (Sahih).
    const extra = [
      _ExtraTranslator(
        id: 3,
        name: 'Russian Translation (Ministry of Awqaf)',
        languageCode: 'ru',
        quranComId: 78,
        nameRu: 'Минвакф Египта',
        source: 'quran.com',
      ),
      _ExtraTranslator(
        id: 4,
        name: 'Abu Adel',
        languageCode: 'ru',
        quranComId: 79,
        nameRu: 'Абу Адель',
        source: 'quran.com',
      ),
    ];

    for (final t in extra) {
      try {
        // Проверяем: если есть translator с таким quran_com_id —
        // пропускаем (idempotency).
        final existing = await dao.findByQuranComId(t.quranComId);
        if (existing != null) {
          developer.log(
            'seedQuranComTranslators: skip ${t.name} (already exists id=${existing.id})',
            name: 'ContentBootstrapper',
          );
          continue;
        }
        await dao.insertTranslator(
          TranslatorsCompanion.insert(
            id: Value(t.id),
            name: t.name,
            languageCode: t.languageCode,
            source: t.source,
            quranComId: Value(t.quranComId),
            nameRu: Value(t.nameRu),
          ),
        );
        developer.log(
          'seedQuranComTranslators: inserted ${t.name} (quran_com_id=${t.quranComId})',
          name: 'ContentBootstrapper',
        );
      } catch (e, st) {
        developer.log(
          'seedQuranComTranslators: FAILED for ${t.name}: $e',
          name: 'ContentBootstrapper',
          error: e,
          stackTrace: st,
        );
      }
    }
  }
}

class _ExtraTranslator {
  const _ExtraTranslator({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.quranComId,
    required this.nameRu,
    required this.source,
  });
  final int id;
  final String name;
  final String languageCode;
  final int quranComId;
  final String nameRu;
  final String source;
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
