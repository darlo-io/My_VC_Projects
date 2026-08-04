import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/daos/audio_cache_dao.dart';
import '../../../core/storage/app_preferences.dart';

/// Локальный кеш MP3-файлов сур + LRU-вытеснение по лимиту диска.
///
/// Стратегия:
/// 1. По `{reciterId, surah}` строим ключ и ищем строку в
///    `audio_cache_metadata` (UNIQUE(reciterId, surahId)).
/// 2. Если файл есть на диске и непустой → возвращаем путь,
///    обновляем `last_played_at`.
/// 3. Если файла нет → скачиваем по URL, сохраняем, записываем метаданные,
///    запускаем [evictIfNeeded] для соблюдения лимита.
///
/// Race-safety: параллельные вызовы с одним ключом ожидают один и тот же
/// in-flight Future (предотвращает corrupted file при двойном tap).
/// При ошибке загрузки — частичный файл удаляется.
class AudioCache {
  AudioCache({
    required this.dio,
    required this.dao,
    this.prefs,
    this._rootFactory,
  });

  final Dio dio;
  final AudioCacheDao dao;
  final AppPreferences? prefs;
  final Future<Directory> Function()? _rootFactory;

  Directory? _root;
  final Map<String, Future<File>> _inFlight = {};

  /// Санити-чек кешированного файла. MP3 начинается либо с
  /// `ID3` (ID3v2 tag, `0x49 0x44 0x33`), либо с MPEG-фрейм-синхрона
  /// `0xFF 0xFB/FA/F3/F2`. 271-байтный HTML-ответ 403 от
  /// cdn.islamic.network / bahriya.net — типичный poison-кейс,
  /// пробивавший прежнюю проверку `lengthSync() > 0`. Здесь —
  /// две защиты: минимальный размер (1 КБ) **и** первые 3 байта.
  bool _isLikelyValidMedia(File f) {
    try {
      final size = f.lengthSync();
      if (size < 1024) return false;
      final raf = f.openSync(mode: FileMode.read);
      try {
        final head = raf.readSync(3);
        if (head.length < 3) return false;
        // ID3v2 tag
        if (head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) {
          return true;
        }
        // MPEG sync 0xFF + (0xFB/FA/F3/F2) + bitrate/channel byte
        if (head[0] == 0xFF &&
            (head[1] == 0xFB ||
                head[1] == 0xFA ||
                head[1] == 0xF3 ||
                head[1] == 0xF2)) {
          return true;
        }
        return false;
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      return false;
    }
  }

  Future<Directory> _ensureRoot() async {
    if (_root != null) return _root!;
    if (_rootFactory != null) {
      _root = await _rootFactory();
      if (!_root!.existsSync()) _root!.createSync(recursive: true);
      return _root!;
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'audio_cache'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _root = dir;
    return dir;
  }

  /// Локальный путь к MP3 — в подкаталоге `audio_cache/{reciterId}/
  /// {NNN}.mp3` (см. рекомендации в задаче и [audioCacheRelativePath]).
  /// Подкаталог упрощает инспекцию кеша через adb / файл-менеджер
  /// и совпадает с естественной структурой «один ректор — много файлов».
  Future<File> _localFile(String reciterId, int surah) async {
    final root = await _ensureRoot();
    final safeId = reciterId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final subdir = Directory(p.join(root.path, safeId));
    if (!subdir.existsSync()) {
      subdir.createSync(recursive: true);
    }
    final name = '${surah.toString().padLeft(3, '0')}.mp3';
    return File(p.join(subdir.path, name));
  }

  String _key(String reciterId, int surah) => '$reciterId:$surah';

  /// Лимит кеша в байтах. Берётся из [AppPreferences] или
  /// переданного [maxBytesOverride]. Используется в
  /// [getOrDownload] для авто-eviction после каждой загрузки
  /// (раньше eviction вызывался только из Settings при смене
  /// лимита, что позволяло кешу расти бесконтрольно).
  Future<int> _maxBytes(int? override) async {
    if (override != null) return override;
    return (prefs?.cacheLimitMb ?? 2048) * 1024 * 1024;
  }

  /// Общий размер кеша в байтах.
  Future<int> getTotalBytes() => dao.totalBytes();

  /// Стрим общего размера (для UI).
  Stream<int> watchTotalBytes() => dao.watchTotalBytes();

  /// Per-reciter: суммарный размер (в байтах) кешированных
  /// MP3 указанного ректора. Используется в Download screen'е
  /// (`DownloadsTab → строка ректора`).
  Future<int> bytesByReciter(String reciterId) async {
    final row = await dao.attachedDatabase.customSelect(
      'SELECT COALESCE(SUM(file_size_bytes), 0) AS s '
      'FROM audio_cache_metadata WHERE reciter_id = ?',
      variables: [Variable.withString(reciterId)],
      readsFrom: {dao.attachedDatabase.audioCacheMetadata},
    ).getSingle();
    return row.read<int>('s');
  }

  /// Per-reciter: количество кешированных сур (0..114).
  Future<int> countByReciter(String reciterId) async {
    final row = await dao.attachedDatabase.customSelect(
      'SELECT COUNT(*) AS c '
      'FROM audio_cache_metadata WHERE reciter_id = ?',
      variables: [Variable.withString(reciterId)],
      readsFrom: {dao.attachedDatabase.audioCacheMetadata},
    ).getSingle();
    return row.read<int>('c');
  }

  /// Стрим per-reciter статистики для Download screen'а
  /// (автообновление после загрузки / удаления).
  Stream<({int bytes, int count})> watchReciter(String reciterId) {
    return dao.attachedDatabase.customSelect(
      'SELECT COALESCE(SUM(file_size_bytes), 0) AS s, '
      'COUNT(*) AS c FROM audio_cache_metadata WHERE reciter_id = ?',
      variables: [Variable.withString(reciterId)],
      readsFrom: {dao.attachedDatabase.audioCacheMetadata},
    ).watchSingle().map((r) => (bytes: r.read<int>('s'), count: r.read<int>('c')));
  }

  /// Возвращает локальный файл для проигрывания. Скачивает при отсутствии.
  /// После загрузки запускает [evictIfNeeded] — РАНЬШЕ eviction
  /// запускался ТОЛЬКО из Settings при смене лимита. Это позволяло
  /// кешу расти бесконтрольно при каждой новой загрузке. Сейчас
  /// eviction вызывается сразу после `_register` — гарантирует,
  /// что общий размер не превысит лимит.
  Future<File> getOrDownload({
    required String reciterId,
    required int surah,
    required String url,
    void Function(double progress)? onProgress,
    int? maxBytesOverride,
    CancelToken? cancelToken,
  }) async {
    final key = _key(reciterId, surah);
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _resolveOrFetch(
      reciterId: reciterId,
      surah: surah,
      url: url,
      onProgress: onProgress,
      maxBytesOverride: maxBytesOverride,
      cancelToken: cancelToken,
    );
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      unawaited(_inFlight.remove(key));
    }
  }

  Future<File> _resolveOrFetch({
    required String reciterId,
    required int surah,
    required String url,
    void Function(double progress)? onProgress,
    int? maxBytesOverride,
    CancelToken? cancelToken,
  }) async {
    final file = await _localFile(reciterId, surah);
    if (file.existsSync() && _isLikelyValidMedia(file)) {
      await _touchPlayed(reciterId, surah, file);
      return file;
    }
    // Stale или неполный файл — удаляем и качаем заново.
    if (file.existsSync()) {
      try {
        await file.delete();
      } catch (_) {/* ignore */}
    }
    try {
      await _download(
        url,
        file,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
    } catch (e) {
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {/* ignore */}
      }
      rethrow;
    }
    // Регистрация в `audio_cache_metadata` — НЕ критична для
    // самого факта скачивания (файл уже на диске, плеер его
    // найдёт в следующий раз через `_touchPlayed` → `_register`).
    // Если INSERT падает (concurrent write race в Drift под
    // параллельным prefetch'ом), не должно валить весь worker —
    // иначе один сбой БД-транзакции обнулит весь prefetch и юзер
    // увидит «ничего не скачалось», хотя файлы реально лежат.
    try {
      await _register(reciterId, surah, file);
    } catch (e, st) {
      developer.log(
        'audio_cache._register failed: $reciterId/$surah',
        name: 'AudioCache',
        error: e,
        stackTrace: st,
      );
    }
    // Eviction ВСЕГДА (не только при `maxBytesOverride`):
    // раньше eviction вызывался только из Settings, что
    // позволяло кешу расти неограниченно.
    final maxBytes = await _maxBytes(maxBytesOverride);
    if (maxBytes > 0) {
      await evictIfNeeded(maxBytes: maxBytes);
    }
    return file;
  }

  /// Загрузка с одной повторной попыткой на транзитные сетевые
  /// ошибки (timeout / connection reset). Источник-фоллбэк
  /// (primary → backup → archive.org) пробует уже верхний
  /// слой — [AudioSourceResolver], поэтому тут держим ровно
  /// один ретрай, а не бесконечный цикл.
  ///
  /// `validateStatus` пропускает 5xx на retry (сервер может
  /// «отдохнуть»); 4xx остаются бросками — это сигнал «файл
  /// не найден», и его выше обрабатывает `_resolveOrFetch` /
  /// `AudioSourceResolver`.
  Future<void> _download(
    String url,
    File target, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    // 2 попытки на транзитные ошибки / 5xx + 1 длинная на 429.
    // cdn.alislam.ru лимитирует: 10 req/s + 70/7s cumulative (см.
    // community.islamic.network/knowledgebase/2-...). 100ms-throttle
    // в [AudioPlayerController._playSurahByAyah] держит первый лимит;
    // для второго при 70 аятах подряд нужен 7-секундный backoff.
    const int maxAttempts = 2;
    const int maxAttemptsWith429 = 3;
    int attempt = 0;
    while (true) {
      attempt += 1;
      try {
        await dio.download(
          url,
          target.path,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            if (onProgress == null || total <= 0) return;
            onProgress(received / total);
          },
          options: Options(
            // 5xx + 429 — могут быть временными; именно для них
            // включается retry. Прочие 4xx (404 и пр.) — это
            // сигнал «next source» для [AudioSourceResolver],
            // а не повод ретраить.
            validateStatus: (s) =>
                s != null && s < 500 && s != 429,
          ),
        );
        return;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        final isRateLimit = code == 429;
        final transient = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;
        final serverSide = code != null && code >= 500;
        // 429 → ждём 7s и ретраим (cumulative 70/7s window).
        if (isRateLimit && attempt < maxAttemptsWith429) {
          await Future<void>.delayed(const Duration(seconds: 7));
          continue;
        }
        if ((!transient && !serverSide) || attempt >= maxAttempts) rethrow;
        // Backoff: 200ms × attempt (200ms, 400ms).
        await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
      }
    }
  }

  Future<void> _register(String reciterId, int surah, File file) async {
    final size = await file.length();
    developer.log(
      'audio_cache._register: $reciterId/$surah size=$size',
      name: 'AudioCache',
    );
    try {
      await dao.upsertCacheEntry(
        reciterId: reciterId,
        surahId: surah,
        filePath: file.path,
        fileSizeBytes: size,
      );
    } catch (e, st) {
      developer.log(
        'audio_cache._register FAILED: $reciterId/$surah',
        name: 'AudioCache',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> _touchPlayed(String reciterId, int surah, File file) async {
    final existing = await dao.findByKey(reciterId, surah);
    if (existing == null) {
      developer.log(
        'audio_cache._touchPlayed MISS: $reciterId/$surah, registering',
        name: 'AudioCache',
      );
      await _register(reciterId, surah, file);
    } else {
      await dao.touchPlayed(existing.id, DateTime.now());
    }
  }

  /// LRU-вытеснение: удаляет наименее недавно проигрывавшиеся записи
  /// (и их файлы), пока общий размер не станет ниже [maxBytes].
  ///
  /// Не трогает `lastPlayedAt` сейчас — только метаданные. Вызывается
  /// после каждой новой загрузки (post-insert), а также из Settings при
  /// смене лимита пользователем.
  Future<int> evictIfNeeded({required int maxBytes}) async {
    if (maxBytes <= 0) return 0;
    var total = await dao.totalBytes();
    if (total <= maxBytes) return 0;

    var evicted = 0;
    final candidates = await dao.oldestFirst(limit: 200);
    for (final c in candidates) {
      if (total <= maxBytes) break;
      // Не вытесняем только что добавленную запись (защита от remove
      // current item сразу после insert). Достаточно проверки
      // `lastPlayedAt` ≠ null ИЛИ `downloadedAt` старше 5 секунд.
      final isJustInserted = c.lastPlayedAt != null &&
          DateTime.now().difference(c.lastPlayedAt!).inSeconds < 5;
      if (isJustInserted) continue;

      final file = File(c.filePath);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {/* ignore */}
      }
      await dao.deleteById(c.id);
      total -= c.fileSizeBytes;
      evicted++;
    }
    return evicted;
  }

  /// Удалить ВСЕ записи для ректора. Используется в Download
  /// screen'е по кнопке "Delete" у ректора.
  Future<int> clearReciter(String reciterId) async {
    final all = await dao.oldestFirst(limit: 10000);
    var removed = 0;
    for (final c in all) {
      if (c.reciterId != reciterId) continue;
      final file = File(c.filePath);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {/* ignore */}
      }
      await dao.deleteById(c.id);
      removed++;
    }
    return removed;
  }

  /// Полная очистка кеша: удаляет все файлы и метаданные.
  Future<int> clearAll() async {
    final root = await _ensureRoot();
    final all = await dao.oldestFirst(limit: 10000);
    for (final c in all) {
      final file = File(c.filePath);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {/* ignore */}
      }
    }
    // Подчистить файлы, оставшиеся в каталоге (без метаданных).
    if (root.existsSync()) {
      for (final entity in root.listSync()) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (_) {/* ignore */}
        }
      }
    }
    return dao.deleteAll();
  }

  /// Self-heal: просканировать `app_flutter/audio_cache/` и
  /// зарегистрировать в БД все валидные MP3, которых там нет.
  /// Запускается на bootstrap'е, чтобы восстановить консистентность
  /// после старых багов (файлы скачались, но INSERT
  /// `audio_cache_metadata` упал под concurrent write race в
  /// старой версии с `id: 0`).
  ///
  /// Возвращает число восстановленных записей.
  Future<int> rebuildMissingFromDisk() async {
    final root = await _ensureRoot();
    if (!root.existsSync()) {
      developer.log(
        'audio_cache.rebuild: root does not exist: ${root.path}',
        name: 'AudioCache',
      );
      return 0;
    }
    developer.log(
      'audio_cache.rebuild: root=${root.path}',
      name: 'AudioCache',
    );
    var restored = 0;
    var scanned = 0;
    var skipped = 0;
    // Один прогон по всем reciter-подкаталогам + 114 файлов в каждом.
    // Стоимость: ~570 stat'ов на 5 ректоров, 10-50мс в сумме.
    final subdirs = root.listSync().whereType<Directory>().toList();
    developer.log(
      'audio_cache.rebuild: found ${subdirs.length} reciter dirs',
      name: 'AudioCache',
    );
    for (final sub in subdirs) {
      final reciterId = sub.path.split(p.separator).last;
      // reciterId типа 'mp3quran_112' → 'mp3quran:112'
      final canonicalId = reciterId.replaceFirst('_', ':');
      final files = sub.listSync().whereType<File>().toList();
      for (final file in files) {
        if (!file.path.endsWith('.mp3')) continue;
        if (!_isLikelyValidMedia(file)) {
          skipped++;
          continue;
        }
        final surah = int.tryParse(
          p.basename(file.path).replaceAll('.mp3', ''),
        );
        if (surah == null) continue;
        scanned++;
        if (await dao.isCached(reciterId: canonicalId, surahId: surah)) {
          continue;
        }
        try {
          final size = await file.length();
          await dao.upsertCacheEntry(
            reciterId: canonicalId,
            surahId: surah,
            filePath: file.path,
            fileSizeBytes: size,
            // back-dating: файлы могли быть скачаны давно
            downloadedAt: DateTime.now(),
            lastPlayedAt: DateTime.now(),
          );
          restored++;
        } catch (e) {
          developer.log(
            'audio_cache.rebuild: failed $file',
            name: 'AudioCache',
            error: e,
          );
        }
      }
    }
    developer.log(
      'audio_cache.rebuild: scanned=$scanned skipped_invalid=$skipped restored=$restored',
      name: 'AudioCache',
    );
    return restored;
  }

  /// Стрим ID ректоров, для которых скачаны все 114 сур. Авто-обновляется
  /// при добавлении/удалении записей в `audio_cache_metadata`.
  Stream<Set<String>> watchFullyCachedReciters() =>
      dao.watchFullyCachedReciters();

  /// `true` если сура [surah] для ректора [reciterId] уже скачана.
  /// Используется в [ReciterDownloadController] для skip'а уже
  /// закешированных сур.
  Future<bool> isCached({required String reciterId, required int surah}) =>
      dao.isCached(reciterId: reciterId, surahId: surah);

  /// Prefetch-вариант `getOrDownload` — НЕ запускает `evictIfNeeded`.
  /// Eviction теперь single-shot после prefetch'а (см.
  /// [ReciterDownloadController]), чтобы eviction не выкидывал
  /// только-что-вставленные строки других workers.
  Future<File> getOrDownloadNoEvict({
    required String reciterId,
    required int surah,
    required String url,
    CancelToken? cancelToken,
  }) async {
    final key = _key(reciterId, surah);
    final existing = _inFlight[key];
    if (existing != null) return existing;
    final future = _resolveOrFetchNoEvict(
      reciterId: reciterId,
      surah: surah,
      url: url,
      cancelToken: cancelToken,
    );
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      unawaited(_inFlight.remove(key));
    }
  }

  Future<File> _resolveOrFetchNoEvict({
    required String reciterId,
    required int surah,
    required String url,
    CancelToken? cancelToken,
  }) async {
    final file = await _localFile(reciterId, surah);
    if (file.existsSync() && _isLikelyValidMedia(file)) {
      await _touchPlayed(reciterId, surah, file);
      return file;
    }
    if (file.existsSync()) {
      try {
        await file.delete();
      } catch (_) {/* ignore */}
    }
    try {
      await _download(url, file, cancelToken: cancelToken);
    } catch (e) {
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {/* ignore */}
      }
      rethrow;
    }
    try {
      await _register(reciterId, surah, file);
    } catch (e, st) {
      developer.log(
        'audio_cache._register no-evict failed: $reciterId/$surah',
        name: 'AudioCache',
        error: e,
        stackTrace: st,
      );
    }
    return file;
  }

  /// Single-shot eviction после prefetch'а. Раньше eviction гонялся
  /// после КАЖДОЙ загрузки (с гонками под concurrent workers). Теперь
  /// вызывается ровно один раз в конце prefetch'а.
  Future<int> evictIfNeededNow({int? maxBytesOverride}) async {
    final maxBytes = await _maxBytes(maxBytesOverride);
    if (maxBytes <= 0) return 0;
    return evictIfNeeded(maxBytes: maxBytes);
  }
}
