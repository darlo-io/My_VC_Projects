// Минимальный HTTPS-сервер для тестирования `ContentUpdateService`.
//
// Отдаёт статические файлы из `--root` (по умолчанию `tool/signed`).
// Запустите на машине разработчика:
//
//   dart run tool/serve_manifest.dart --root tool/signed --port 8443
//
// Перед первым запуском сгенерируйте self-signed cert:
//
//   pwsh -c "New-SelfSignedCertificate -DnsName 'quran-app.local','localhost' -CertStoreLocation 'Cert:\CurrentUser\My' ..."
//
//   & 'C:\Program Files\Git\bin\bash.exe' -c \
//     "openssl pkcs12 -in tool/certs/server.pfx -nocerts -nodes -passin pass:quranapp \
//      | openssl rsa -out tool/certs/server.key && \
//      openssl pkcs12 -in tool/certs/server.pfx -clcerts -nokeys -passin pass:quranapp \
//      > tool/certs/server.crt"
//
// Из эмулятора Android: `https://quran-app.local:8443` (нужно
// добавить в `/etc/hosts` через `adb` или настроить `network_security_config.xml`).
// Из физического устройства: `https://<your-LAN-IP>:8443`.
//
// Передайте URL в приложение через `--dart-define`:
//   flutter run --dart-define=QURAN_MANIFEST_BASE=https://quran-app.local:8443/v1
//
// (см. [quranManifestFallbackEndpoints] в `quran_api.dart` —
// значение по умолчанию для продового endpoint'а, перебивается
// через --dart-define.)

import 'dart:io';

Future<void> main(List<String> args) async {
  final root = args.length > 1 && args[0] == '--root' ? args[1] : 'tool/signed';
  final portArg = args.indexOf('--port');
  final port = portArg >= 0 ? int.parse(args[portArg + 1]) : 8443;
  final certPath = args.indexOf('--cert') >= 0
      ? args[args.indexOf('--cert') + 1]
      : 'tool/certs/server.crt';
  final keyPath = args.indexOf('--key') >= 0
      ? args[args.indexOf('--key') + 1]
      : 'tool/certs/server.key';

  // Загружаем self-signed cert + private key в `SecurityContext`.
  final ctx = SecurityContext();
  try {
    ctx.useCertificateChain(certPath);
    ctx.usePrivateKey(keyPath);
  } catch (e) {
    print('Failed to load TLS cert/key: $e');
    print('Cert: $certPath (exists: ${File(certPath).existsSync()})');
    print('Key:  $keyPath (exists: ${File(keyPath).existsSync()})');
    print('Generate one with:');
    print('  pwsh -c "New-SelfSignedCertificate -DnsName quran-app.local,localhost"');
    print('  See header comments for full instructions.');
    exit(1);
  }

  final server = await HttpServer.bindSecure(
    InternetAddress.anyIPv4,
    port,
    ctx,
  );
  print(
    'Serving ${Directory(root).absolute.path} on https://${server.address.host}:${server.port}',
  );
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
      // ignore: avoid_print
      print('  ${req.method} $path → 200 (${bytes.length} bytes)');
    } else {
      req.response.statusCode = HttpStatus.notFound;
      req.response.write('Not found: $path');
      // ignore: avoid_print
      print('  ${req.method} $path → 404');
    }
    await req.response.close();
  }
}
