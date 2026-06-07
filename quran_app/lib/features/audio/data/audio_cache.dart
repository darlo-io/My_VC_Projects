import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/audio_cache_dao.dart';

/// Локальный кеш MP3-файлов сур.
///
/// Стратегия:
/// 1. По `{reciterId, surah}` ищем строку в `audio_cache_metadata`.
/// 2. Если файл есть на диске → возвращаем путь.
/// 3. Если файла нет → скачиваем по URL, сохраняем, записываем метаданные.
///
/// LRU-вытеснение: в этой итерации (audio foundation) — простая версия
/// по `last_played_at`. Полная LRU-политика с лимитом диска и авто-чисткой
/// будет в следующей итерации (см. ARCHITECTURE §14).
class AudioCache {
  AudioCache({required this.dio, required this.dao});

  final Dio dio;
  final AudioCacheDao dao;

  Directory? _root;

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

  /// Строит локальный путь для файла суры данного ректора.
  Future<File> _localFile(String reciterId, int surah) async {
    final root = await _ensureRoot();
    final safeId = reciterId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final name = '${safeId}_${surah.toString().padLeft(3, '0')}.mp3';
    return File(p.join(root.path, name));
  }

  /// Возвращает локальный файл для проигрывания. Скачивает при отсутствии.
  Future<File> getOrDownload({
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
    await _download(url, file, onProgress: onProgress);
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
