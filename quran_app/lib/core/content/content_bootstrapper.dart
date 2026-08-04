import 'dart:async';
import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../features/audio/data/reciters_repository.dart';
import '../../features/audio/data/reciters_sync_service.dart';
import '../../features/audio/data/audio_cache.dart';
import '../database/app_database.dart';
import '../database/daos/ayah_dao.dart';
import '../database/daos/surah_dao.dart';
import '../database/daos/translation_dao.dart';
import '../database/surah_ru_names.dart';
import 'content_manifest.dart';
import 'content_update_service.dart';

class ContentBootstrapper {
  ContentBootstrapper({
    required this.db,
    required this.surahDao,
    required this.ayahDao,
    required this.translationDao,
    required this.manifestRepository,
    required this.recitersRepository,
    this.contentUpdateService,
    this.audioCache,
    this.recitersSyncService,
  });

  final AppDatabase db;
  final SurahDao surahDao;
  final AyahDao ayahDao;
  final TranslationDao translationDao;
  final ContentManifestRepository manifestRepository;
  final RecitersRepository recitersRepository;

  /// Опциональный [ContentUpdateService] для network-fetch +
  /// verify + apply manifest'а. Передаётся вызывающим (см.
  /// [contentBootstrapperProvider]) через DI. Round 9.5 (code review
  /// #C3): добавлен в конструктор вместо mutable public field,
  /// чтобы избежать late-mutation и упростить тестирование.
  final ContentUpdateService? contentUpdateService;

  /// Опциональный [AudioCache] для self-heal'а на bootstrap'е:
  /// просканировать `app_flutter/audio_cache/` и зарегистрировать
  /// файлы, у которых нет строки в `audio_cache_metadata`. Передаётся
  /// через DI.
  final AudioCache? audioCache;

  /// Опциональный [RecitersSyncService] для фоновой синхронизации
  /// списка чтецов с mp3quran.net после bootstrap. Если не передан —
  /// sync не запускается (можно держать мобильное приложение в
  /// «offline-first» режиме с только 8 дефолтными ректорами в кеше).
  final RecitersSyncService? recitersSyncService;

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

  /// Загрузить контент. Round 9.4: только-вставка translators
  /// (idempotently). Вызывается из `main.dart` через
  /// postFrameCallback на каждом cold start, чтобы existing
  /// installations получили новых переводчиков даже если bootstrap
  /// screen пропускается.
  Future<void> seedTranslators() async {
    developer.log('seedTranslators START', name: 'ContentBootstrapper');
    try {
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

      // Repair-pass: на старых install'ах v11→v12 backfill отработал
      // вхолостую (таблица surahs была ещё пуста на момент миграции),
      // и `name_ru`/`subtitle_ru` остались NULL. Заполняем
      // идемпотентно из констант — один UPDATE на колонку. Это
      // срабатывает один раз на «починенном» устройстве, на
      // следующих запусках — no-op (rows already set).
      await _backfillMissingRussianSurahNames();

      progress.value = const BootstrapProgress.complete(offline: true);
    } else {
      // Round 9.4: cold install без quran_full.json.
      // translators уже seedятся через seedTranslators() (Round 8).
      // verses и surahs metadata будут загружены lazy-load'ом
      // при первом открытии Reader через AyahsService.
      progress.value = const BootstrapProgress.complete(offline: false);
    }

    // 2) Сетевой fetch — best-effort, не блокирует UI. Если не
    // получится — приложение работает на lazy-fetch данных. Запускаем
    // в ОБОИХ ветках (cold install + warm start) — это критично:
    // без него ContentUpdateService никогда не сработает на
    // устройствах, где seed-bootstrap уже завершился.
    unawaited(_fetchFromNetworkInBackground());

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
  /// имена при bootstrap'е.
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

  /// В фоне: проверка обновлений через сеть. Не критично.
  ///
  /// Round 9.4: bulk download через `ContentDownloader` больше не
  /// используется — данные загружаются лениво через
  /// `AyahsService.ensureLoaded()` (verses + metadata, Round 9.2B)
  /// и `QuranTranslationSyncService.ensureTranslatorLoaded()`
  /// (translations, Round 8.3). `ContentUpdateService.checkAndApply`
  /// остаётся для network-delivered manifest обновлений.
  ///
  /// Round 9.5 (code review #C3): использует поле `contentUpdateService`
  /// вместо параметра — DI передаётся через конструктор.
  Future<void> _fetchFromNetworkInBackground() async {
    final service = contentUpdateService;
    if (service == null) {
      developer.log(
        'contentUpdateService not injected — skipping network fetch',
        name: 'ContentBootstrapper',
      );
      return;
    }
    try {
      networkProgress.value = const NetworkFetchProgress.started();
      await service.checkAndApply();
      networkProgress.value = const NetworkFetchProgress.completed();
    } catch (_) {
      networkProgress.value = const NetworkFetchProgress.failed();
    }
  }

  /// Round 8: добавляет новых переводчиков из Quran.com API
  /// (Ministry of Awqaf Egypt id=78, Abu Adel id=79). Использует
  /// PK id=3 и id=4 (id=1,2 заняты Kuliev/Sahih из старого seed).
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
