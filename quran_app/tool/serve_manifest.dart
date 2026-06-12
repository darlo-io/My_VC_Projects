// Минимальный HTTP-сервер для тестирования `ContentUpdateService`.
// Отдаёт статические файлы из `--root` (по умолчанию `tool/signed`).
// Запустите на машине разработчика:
//
//   dart run tool/serve_manifest.dart --root tool/signed --port 8765
//
// Из эмулятора Android: `http://10.0.2.2:8765` (host-loopback).
// Из физического устройства: `http://<your-LAN-IP>:8765`.
// Из web/desktop: `http://localhost:8765`.
//
// Передайте URL в приложение через `--dart-define`:
//   flutter run --dart-define=QURAN_MANIFEST_BASE=http://10.0.2.2:8765/v1
//
// (см. [quranManifestFallbackEndpoints] в `quran_api.dart` —
// значение по умолчанию для продового endpoint'а, перебивается
// через --dart-define.)

import 'dart:io';

Future<void> main(List<String> args) async {
  final root = args.length > 1 && args[0] == '--root' ? args[1] : 'tool/signed';
  final portArg = args.indexOf('--port');
  final port = portArg >= 0 ? int.parse(args[portArg + 1]) : 8765;

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('Serving ${Directory(root).absolute.path} on http://${server.address.host}:${server.port}');
  print('Press Ctrl+C to stop.');

  await for (final req in server) {
    var path = req.uri.path;
    if (path == '/') {
      path = '/manifest.json';
    } else if (path.startsWith('/v1/') || path.startsWith('/v2/')) {
      // Strip version prefix — статические файлы лежат
      // без него (`tool/signed/manifest.json`,
      // `tool/signed/payloads/quran-X.Y.Z.json`).
      path = path.substring(3);
    }
    final file = File('${Directory(root).absolute.path}$path');
    if (file.existsSync()) {
      final bytes = await file.readAsBytes();
      final contentType = path.endsWith('.json')
          ? ContentType.json
          : ContentType.binary;
      req.response.headers.contentType = contentType;
      req.response.headers.add('Access-Control-Allow-Origin', '*');
      req.response.add(bytes);
      print('  ${req.method} $path → 200 (${bytes.length} bytes)');
    } else {
      req.response.statusCode = HttpStatus.notFound;
      req.response.write('Not found: $path');
      print('  ${req.method} $path → 404');
    }
    await req.response.close();
  }
}
