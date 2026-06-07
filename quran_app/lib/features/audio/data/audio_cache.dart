import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/audio_cache_dao.dart';

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
  AudioCache({required this.dio, required this.dao});

  final Dio dio;
  final AudioCacheDao dao;

  Directory? _root;
  final Map<String, Future<File>> _inFlight = {};

  Future<Directory> _ensureRoot() async {
    if (_root != null) return _root!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'audio_cache'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _root = dir;
    return dir;
  }

  Future<File> _localFile(String reciterId, int surah) async {
    final root = await _ensureRoot();
    final safeId = reciterId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final name = '${safeId}_${surah.toString().padLeft(3, '0')}.mp3';
    return File(p.join(root.path, name));
  }

  String _key(String reciterId, int surah) => '$reciterId:$surah';

  /// Общий размер кеша в байтах.
  Future<int> getTotalBytes() => dao.totalBytes();

  /// Стрим общего размера (для UI).
  Stream<int> watchTotalBytes() => dao.watchTotalBytes();

  /// Возвращает локальный файл для проигрывания. Скачивает при отсутствии.
  /// После загрузки запускает [evictIfNeeded] (переданный лимит читается
  /// через [maxBytesOverride] — если null, eviction не выполняется; UI
  /// вызывает [evictIfNeeded] отдельно при смене лимита).
  Future<File> getOrDownload({
    required String reciterId,
    required int surah,
    required String url,
    void Function(double progress)? onProgress,
    int? maxBytesOverride,
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
  }) async {
    final file = await _localFile(reciterId, surah);
    if (file.existsSync() && file.lengthSync() > 0) {
      await _touchPlayed(reciterId, surah, file);
      return file;
    }
    try {
      await _download(url, file, onProgress: onProgress);
    } catch (e) {
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {/* ignore */}
      }
      rethrow;
    }
    await _register(reciterId, surah, file);
    if (maxBytesOverride != null) {
      await evictIfNeeded(maxBytes: maxBytesOverride);
    }
    return file;
  }

  Future<void> _download(
    String url,
    File target, {
    void Function(double progress)? onProgress,
  }) async {
    await dio.download(
      url,
      target.path,
      onReceiveProgress: (received, total) {
        if (onProgress == null || total <= 0) return;
        onProgress(received / total);
      },
    );
  }

  Future<void> _register(String reciterId, int surah, File file) async {
    final size = await file.length();
    await dao.insert(
      AudioCacheMetadatum(
        id: 0, // autoIncrement подставит реальный id
        reciterId: reciterId,
        surahId: surah,
        filePath: file.path,
        fileSizeBytes: size,
        downloadedAt: DateTime.now(),
        lastPlayedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _touchPlayed(String reciterId, int surah, File file) async {
    final existing = await dao.findByKey(reciterId, surah);
    if (existing == null) {
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
}
