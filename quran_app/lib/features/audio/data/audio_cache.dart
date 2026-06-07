import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/audio_cache_dao.dart';

/// Локальный кеш MP3-файлов сур.
///
/// Стратегия:
/// 1. По `{reciterId, surah}` строим ключ и ищем строку в
///    `audio_cache_metadata` (UNIQUE(reciterId, surahId)).
/// 2. Если файл есть на диске и непустой → возвращаем путь.
/// 3. Если файла нет → скачиваем по URL, сохраняем, записываем метаданные.
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

  /// Возвращает локальный файл для проигрывания. Скачивает при отсутствии.
  Future<File> getOrDownload({
    required String reciterId,
    required int surah,
    required String url,
    void Function(double progress)? onProgress,
  }) async {
    final key = _key(reciterId, surah);
    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _resolveOrFetch(
      reciterId: reciterId,
      surah: surah,
      url: url,
      onProgress: onProgress,
    );
    _inFlight[key] = future;
    try {
      return await future;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<File> _resolveOrFetch({
    required String reciterId,
    required int surah,
    required String url,
    void Function(double progress)? onProgress,
  }) async {
    final file = await _localFile(reciterId, surah);
    if (file.existsSync() && file.lengthSync() > 0) {
      await _touchPlayed(reciterId, surah, file);
      return file;
    }
    try {
      await _download(url, file, onProgress: onProgress);
    } catch (e) {
      // Не оставлять partial-файл: следующий вызов прочтёт его как
      // валидный кеш и подаст плееру битый MP3.
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (_) {/* ignore */}
      }
      rethrow;
    }
    await _register(reciterId, surah, file);
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
}
