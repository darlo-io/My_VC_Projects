import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:quran_app/core/database/app_database.dart';
import 'package:quran_app/core/database/daos/audio_cache_dao.dart';
import 'package:quran_app/features/audio/data/audio_cache.dart';

/// Deterministic, hermetic tests for [AudioCache] LRU eviction.
///
/// These tests run with `flutter test` (not `dart test`) because
/// `Drift` + `NativeDatabase.memory()` need the Flutter binding for
/// isolates. There is **no real network** — `Dio.httpClientAdapter`
/// is replaced with [_FakeAdapter], which writes a deterministic
/// byte payload of `_sizeBytes(reciter, surah)` bytes to a temp
/// file before reporting completion.
///
/// What we lock in (matches master plan §4.1 LRU GC):
///   1. Insert N entries → total > limit → oldest evicted, files
///      deleted from disk, DB row count drops accordingly.
///   2. The "just-inserted" 5-second guard prevents evicting the
///      item we just downloaded.
///   3. Cache hit (file exists + non-empty) does NOT re-download.
///   4. Parallel calls to [AudioCache.getOrDownload] with the same
///      `{reciter, surah}` deduplicate to a single in-flight Future.
///   5. [AudioCache.clearReciter] removes only that reciter's files.
void main() {
  late AppDatabase db;
  late AudioCacheDao dao;
  late Directory tmpRoot;
  late Directory dlRoot;

  // Each "download" writes this many bytes per entry. The LRU
  // arithmetic is built around this constant.
  const int sizePerEntry = 100;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.audioCacheDao;
    tmpRoot = await Directory.systemTemp.createTemp('audio_cache_test_');
    dlRoot = await tmpRoot.createTemp('dl_');
  });

  tearDown(() async {
    await db.close();
    if (tmpRoot.existsSync()) {
      await tmpRoot.delete(recursive: true);
    }
  });

  /// Build an [AudioCache] wired to the in-memory DB and a fake Dio.
  /// `cacheLimitMb=null` + `maxBytesOverride` keeps prefs out of
  /// the equation; we always pass an explicit byte limit to eviction.
  AudioCache buildCache(Dio dio) => AudioCache(
        dio: dio,
        dao: dao,
        rootFactory: () async => dlRoot,
      );

  test('LRU: oldest entries are evicted first, files deleted from disk',
      () async {
    final adapter = _FakeAdapter(
      writeTo: dlRoot,
      sizeBytes: sizePerEntry,
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final cache = buildCache(dio);

    // 1) Insert 10 entries of 100 bytes each = 1000 bytes.
    for (var s = 1; s <= 10; s++) {
      await cache.getOrDownload(
        reciterId: 'ar.alafasy',
        surah: s,
        url: 'https://fake/$s.mp3',
      );
      // Stagger last_played_at so eviction order is deterministic.
      // Otherwise all entries land with `lastPlayedAt = now`, and
      // `oldestFirst()` ordering becomes non-deterministic on the
      // sub-second scale.
      await dao.touchPlayed(
        (await dao.findByKey('ar.alafasy', s))!.id,
        DateTime.now().subtract(Duration(seconds: 100 - s)),
      );
    }

    // Sanity: all 10 entries are on disk.
    expect(_filesInRoot(dlRoot).length, 10);
    expect(await dao.totalBytes(), 1000);

    // 2) Set a tight limit that requires evicting exactly 5 entries
    //    (500 bytes left = 5 entries of 100 bytes).
    final evicted = await cache.evictIfNeeded(maxBytes: 500);
    expect(evicted, 5);

    // 3) The 5 OLDEST (surahs 1..5) are gone — both file and DB row.
    for (var s = 1; s <= 5; s++) {
      final path = p.join(dlRoot.path, 'ar.alafasy_${s.toString().padLeft(3, '0')}.mp3');
      expect(File(path).existsSync(), isFalse,
          reason: 'surah $s file should have been evicted');
      expect(await dao.findByKey('ar.alafasy', s), isNull,
          reason: 'surah $s metadata should have been deleted');
    }
    // 4) The 5 NEWEST (surahs 6..10) survive.
    for (var s in [6, 7, 8, 9, 10]) {
      final path = p.join(dlRoot.path, 'ar.alafasy_${s.toString().padLeft(3, '0')}.mp3');
      expect(File(path).existsSync(), isTrue,
          reason: 'surah $s file should still exist');
      expect(await dao.findByKey('ar.alafasy', s), isNotNull);
    }

    // 5) Total now ≤ 500 bytes.
    expect(await dao.totalBytes(), lessThanOrEqualTo(500));
  });

  test('LRU: just-inserted entry within 5s is protected from eviction',
      () async {
    final adapter = _FakeAdapter(writeTo: dlRoot, sizeBytes: sizePerEntry);
    final dio = Dio()..httpClientAdapter = adapter;
    final cache = buildCache(dio);

    // 1 entry, freshly inserted → must NOT be evicted at any limit > 0.
    await cache.getOrDownload(
      reciterId: 'ar.alafasy',
      surah: 1,
      url: 'https://fake/1.mp3',
    );

    final evicted = await cache.evictIfNeeded(maxBytes: 1);
    expect(evicted, 0);
    expect(await dao.totalBytes(), 100,
        reason: 'the just-inserted entry must survive');
    final path = p.join(dlRoot.path, 'ar.alafasy_001.mp3');
    expect(File(path).existsSync(), isTrue);
  });

  test('evictIfNeeded with maxBytes <= 0 short-circuits (no-op)', () async {
    final adapter = _FakeAdapter(writeTo: dlRoot, sizeBytes: sizePerEntry);
    final dio = Dio()..httpClientAdapter = adapter;
    final cache = buildCache(dio);

    await cache.getOrDownload(
      reciterId: 'ar.alafasy',
      surah: 1,
      url: 'https://fake/1.mp3',
    );
    // maxBytes <= 0 ⇒ eviction disabled (consistent with
    // `prefs.cacheLimitMb = 0` semantics — see `AudioCache._maxBytes`).
    expect(await cache.evictIfNeeded(maxBytes: 0), 0);
    expect(await cache.evictIfNeeded(maxBytes: -1), 0);
  });

  test('evictIfNeeded is a no-op when total ≤ limit', () async {
    final adapter = _FakeAdapter(writeTo: dlRoot, sizeBytes: sizePerEntry);
    final dio = Dio()..httpClientAdapter = adapter;
    final cache = buildCache(dio);

    for (var s = 1; s <= 3; s++) {
      await cache.getOrDownload(
        reciterId: 'ar.alafasy',
        surah: s,
        url: 'https://fake/$s.mp3',
      );
    }
    // 300 bytes total, limit 1000 → nothing to evict.
    expect(await cache.evictIfNeeded(maxBytes: 1000), 0);
    expect(await dao.totalBytes(), 300);
  });

  test('cache hit does NOT re-download (no second network call)', () async {
    final adapter = _CountingAdapter(
      writeTo: dlRoot,
      sizeBytes: sizePerEntry,
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final cache = buildCache(dio);

    // First call → 1 network download.
    final file1 = await cache.getOrDownload(
      reciterId: 'ar.alafasy',
      surah: 1,
      url: 'https://fake/1.mp3',
    );
    expect(adapter.callCount, 1);
    expect(file1.existsSync(), isTrue);

    // Second call → 0 downloads (file already exists, just touches
    // `last_played_at`).
    final file2 = await cache.getOrDownload(
      reciterId: 'ar.alafasy',
      surah: 1,
      url: 'https://fake/1.mp3',
    );
    expect(adapter.callCount, 1,
        reason: 'cache hit must not trigger a second network call');
    expect(file2.path, file1.path);
  });

  test('parallel getOrDownload with same key dedupes to one Future',
      () async {
    final adapter = _CountingAdapter(
      writeTo: dlRoot,
      sizeBytes: sizePerEntry,
      // Slow adapter so both Futures actually race the same in-flight
      // request (otherwise the first might finish before the second
    // starts).
      delay: const Duration(milliseconds: 50),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final cache = buildCache(dio);

    final f1 = cache.getOrDownload(
      reciterId: 'ar.alafasy',
      surah: 7,
      url: 'https://fake/7.mp3',
    );
    final f2 = cache.getOrDownload(
      reciterId: 'ar.alafasy',
      surah: 7,
      url: 'https://fake/7.mp3',
    );
    final results = await Future.wait([f1, f2]);
    expect(results.map((f) => f.path).toSet(), hasLength(1),
        reason: 'both calls must resolve to the same file');
    expect(adapter.callCount, 1,
        reason: 'race-safety must collapse to a single download');
  });

  test('clearReciter removes only the target reciter', () async {
    final adapter = _FakeAdapter(writeTo: dlRoot, sizeBytes: sizePerEntry);
    final dio = Dio()..httpClientAdapter = adapter;
    final cache = buildCache(dio);

    // 2 reciters × 3 surahs.
    for (var s = 1; s <= 3; s++) {
      await cache.getOrDownload(
        reciterId: 'ar.alafasy',
        surah: s,
        url: 'https://fake/alafasy/$s.mp3',
      );
      await cache.getOrDownload(
        reciterId: 'ar.minshawi',
        surah: s,
        url: 'https://fake/minshawi/$s.mp3',
      );
    }
    expect(_filesInRoot(dlRoot).length, 6);

    final removed = await cache.clearReciter('ar.alafasy');
    expect(removed, 3);
    // Alafasy gone, Minshawi intact.
    for (var s = 1; s <= 3; s++) {
      final alafasyPath = p.join(dlRoot.path,
          'ar.alafasy_${s.toString().padLeft(3, '0')}.mp3');
      final minshawiPath = p.join(dlRoot.path,
          'ar.minshawi_${s.toString().padLeft(3, '0')}.mp3');
      expect(File(alafasyPath).existsSync(), isFalse);
      expect(File(minshawiPath).existsSync(), isTrue);
    }
    expect(await dao.totalBytes(), 300);
  });

  test('partial download: failed Dio call leaves no orphan file',
      () async {
    final adapter = _FakeAdapter(
      writeTo: dlRoot,
      sizeBytes: sizePerEntry,
      // URLs containing "boom" → simulated failure.
      throwFor: (url) => url.contains('boom'),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final cache = buildCache(dio);

    await expectLater(
      () => cache.getOrDownload(
        reciterId: 'ar.alafasy',
        surah: 1,
        url: 'https://fake/boom.mp3',
      ),
      throwsA(isA<DioException>()),
    );
    // No partial file, no orphan DB row.
    final path = p.join(dlRoot.path, 'ar.alafasy_001.mp3');
    expect(File(path).existsSync(), isFalse,
        reason: 'partial file must be cleaned up on failure');
    expect(await dao.findByKey('ar.alafasy', 1), isNull,
        reason: 'no metadata row must be created on failure');
  });
}

/// Lists all `*.mp3` files directly under [dir].
List<File> _filesInRoot(Directory dir) =>
    dir.listSync().whereType<File>().toList();

/// Writes a deterministic byte payload to the target file and
/// returns 200. Used by both [_FakeAdapter] and [_CountingAdapter].
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({
    required this.writeTo,
    required this.sizeBytes,
    this.delay = Duration.zero,
    this.throwFor,
  });

  final Directory writeTo;
  final int sizeBytes;
  final Duration delay;
  final bool Function(String url)? throwFor;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final url = options.uri.toString();
    if (throwFor?.call(url) ?? false) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: 'simulated failure for $url',
      );
    }
    // Dio `download()` сам пишет `ResponseBody.stream` в savePath,
    // переданный в `dio.download(url, target.path)`. Поэтому
    // наш fake только возвращает байты, и `AudioCache`
    // получает заполненный файл на правильном пути.
    final bytes = Uint8List(sizeBytes);
    for (var i = 0; i < sizeBytes; i++) {
      bytes[i] = i & 0xFF;
    }
    return ResponseBody.fromBytes(bytes, 200);
  }

  @override
  void close({bool force = false}) {}
}

/// Like [_FakeAdapter] but counts the number of network calls —
/// used to assert "no second download on cache hit" / "race dedupe".
class _CountingAdapter extends _FakeAdapter {
  _CountingAdapter({
    required super.writeTo,
    required super.sizeBytes,
    super.delay,
  });

  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    return super.fetch(options, requestStream, cancelFuture);
  }
}
