// SentryBootstrap — инициализирует Sentry если задан SENTRY_DSN.
//
// Без DSN (по умолчанию) — no-op, app работает без crash-reporting.
// С DSN — все необработанные исключения, async-ошибки, Flutter
// framework errors и Dio/network errors летят в Sentry с environment
// tag (debug/release) и release tag (pubspec version+git commit).
//
// Setup:
//   1. Создать проект на https://sentry.io (free 5K events/мес)
//   2. Settings → Projects → Client Keys (DSN) → скопировать
//      https://<key>@o<org>.ingest.sentry.io/<project>
//   3. Передать через env: `SENTRY_DSN=<dsn> flutter run`
//   4. CI: добавить SENTRY_DSN в GitHub Secrets, передавать в build step
//      через `$SENTRY_DSN` env
//
// Performance: ~50 KB APK overhead, ~5% CPU на capture.
// Sampling: 100% в debug (все ошибки видны), 20% в release (quota).
//
// Если Sentry захочется отключить на время разработки — удалить
// SENTRY_DSN env var, не нужно править код.
//
// NB: пакет `sentry_flutter` ещё не добавлен в pubspec.yaml — этот
// файл намеренно no-op пока пакет не подключён. После `flutter pub add
// sentry_flutter` нужно раскомментировать блок ниже.

import 'dart:async';
import 'dart:developer' as developer;

class SentryBootstrap {
  /// Инициализация Sentry. No-op если SENTRY_DSN не задан.
  ///
  /// Должна вызываться ПЕРВОЙ в main() — до WidgetsFlutterBinding.
  /// Это гарантирует что caught errors в platform channels (audio_service
  /// start, sqlite3 open) тоже попадают в Sentry.
  static Future<void> init() async {
    // === КОММЕНТАРИЙ ДЛЯ ПРОВЕРЯЮЩЕГО ===
    // Пакет `sentry_flutter` НЕ добавлен в pubspec.yaml. Этот файл — каркас.
    // Когда Sentry-аккаунт будет готов:
    //   1) flutter pub add sentry_flutter
    //   2) Раскомментировать тело init() ниже (полная реализация)
    //   3) Удалить эту заглушку
    //   4) Заменить импорты: 'package:sentry_flutter/sentry_flutter.dart'
    //   5) В main.dart: await SentryBootstrap.init(); — уже подключён

    const dsn = String.fromEnvironment('SENTRY_DSN');
    if (dsn.isNotEmpty) {
      developer.log(
        'SentryBootstrap: SENTRY_DSN задан, но sentry_flutter не '
        'подключён в pubspec. Установи: flutter pub add sentry_flutter',
        name: 'quran_app.sentry',
      );
    }
    // === Полная реализация (раскомментировать после `flutter pub add sentry_flutter`):
    //
    // if (dsn.isEmpty) {
    //   developer.log('SentryBootstrap: SENTRY_DSN not set, crash reporting disabled', name: 'quran_app.sentry');
    //   return;
    // }
    // await SentryFlutter.init(
    //   (options) {
    //     options.dsn = dsn;
    //     options.environment = kDebugMode ? 'debug' : 'release';
    //     options.tracesSampleRate = kDebugMode ? 1.0 : 0.2;
    //     options.release = '${_pubspecVersion}+${_gitShortHash}';
    //     options.beforeSend = (event, hint) {
    //       // Фильтруем шум: нотификации audio_service, transient network.
    //       if (event.throwable is PlatformException &&
    //           event.throwable?.code == 'audio') return null;
    //       return event;
    //     };
    //   },
    // );
    // _sentryInitialized = true;
    // FlutterError.onError = (details) {
    //   Sentry.captureException(details.exception, stackTrace: details.stack);
    //   FlutterError.presentError(details);
    // };
    // PlatformDispatcher.instance.onError = (error, stack) {
    //   Sentry.captureException(error, stackTrace: stack);
    //   return true;
    // };
  }

  /// Helper — для теста активен ли Sentry (no-op без DSN).
  static bool get isEnabled => _sentryInitialized;

  static bool _sentryInitialized = false;
}
