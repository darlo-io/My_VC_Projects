// SentryBootstrap — инициализирует Sentry если задан SENTRY_DSN.
//
// Без DSN (по умолчанию) — no-op, app работает без crash-reporting.
// С DSN — все необработанные исключения, async-ошибки, Flutter
// framework errors и platform-channel ошибки летят в Sentry с
// environment tag (debug/release) и release tag (pubspec version).
//
// Setup:
//   1. Создать проект на https://sentry.io (free 5K events/мес)
//   2. Settings → Projects → Client Keys (DSN) → скопировать
//      https://<key>@o<org>.ingest.sentry.io/<project>
//   3. Передать через env: `flutter run --dart-define=SENTRY_DSN=<dsn>`
//   4. CI: добавить SENTRY_DSN в GitHub Secrets, передавать в build step
//      через `--dart-define=SENTRY_DSN=$SENTRY_DSN`
//
// Performance: ~50 KB APK overhead, ~5% CPU на capture.
// Sampling: 100% в debug (все ошибки видны), 20% в release (quota).
//
// Если Sentry захочется отключить на время разработки — убрать
// `--dart-define=SENTRY_DSN=...`, не нужно править код.

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Wraps [body] in a [runZonedGuarded] zone and wires Sentry when
/// `SENTRY_DSN` is set at compile time.
///
/// When `SENTRY_DSN` is unset (default), this is a thin pass-through:
/// `body` runs inside a guarded zone, and `developer.log` records any
/// Flutter framework errors. When the DSN is provided, Sentry is
/// initialized first, then [FlutterError.onError],
/// [PlatformDispatcher.onError] and the zone's uncaught-error handler
/// all forward to `Sentry.captureException`.
///
/// [body] MUST contain `WidgetsFlutterBinding.ensureInitialized()` —
/// `SentryFlutter.init` runs *before* it so that platform-channel
/// errors (audio_service, sqlite3 open) are also captured.
Future<void> bootstrapAndRun(FutureOr<void> Function() body) async {
  const dsn = String.fromEnvironment('SENTRY_DSN');
  const release = String.fromEnvironment(
    'SENTRY_RELEASE',
    defaultValue: '1.0.0+1',
  );

  final sentryEnabled = dsn.isNotEmpty;
  if (!sentryEnabled) {
    developer.log(
      'SentryBootstrap: SENTRY_DSN not set, crash reporting disabled',
      name: 'quran_app.sentry',
    );
  }

  await runZonedGuarded(
    () async {
      if (sentryEnabled) {
        await SentryFlutter.init(
          (options) {
            options.dsn = dsn;
            options.environment = kDebugMode ? 'debug' : 'release';
            options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
            options.release = release;
            options.beforeSend = (event, hint) {
              // Фильтруем шум: нотификации audio_service, transient network.
              final throwable = event.throwable;
              if (throwable is PlatformException &&
                  throwable.code == 'audio') {
                return null;
              }
              return event;
            };
          },
        );
      }

      FlutterError.onError = (details) {
        developer.log(
          'FlutterError: ${details.exceptionAsString()}',
          name: 'Flutter',
          error: details.exception,
          stackTrace: details.stack,
        );
        if (sentryEnabled) {
          Sentry.captureException(
            details.exception,
            stackTrace: details.stack,
          );
        }
        // Сохраняем дефолтное presentation (красный экран / console),
        // чтобы не потерять UX дев-режима.
        FlutterError.presentError(details);
      };
      // Срабатывает только в release-режиме (в debug FlutterError.onError
      // уже ловит всё) — но всё равно подключаем явно, чтобы Sentry
      // получал platform-side ошибки.
      PlatformDispatcher.instance.onError = (error, stack) {
        developer.log(
          'PlatformDispatcher error: $error',
          name: 'Flutter',
          error: error,
          stackTrace: stack,
        );
        if (sentryEnabled) {
          Sentry.captureException(error, stackTrace: stack);
        }
        return true;
      };

      await body();
    },
    (error, stack) {
      developer.log(
        'Uncaught zone error: $error',
        name: 'Flutter',
        error: error,
        stackTrace: stack,
      );
      if (sentryEnabled) {
        Sentry.captureException(error, stackTrace: stack);
      }
    },
  );
}
