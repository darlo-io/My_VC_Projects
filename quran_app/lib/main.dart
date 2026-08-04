import 'dart:async';
import 'dart:developer' as developer;


import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/observability/sentry_bootstrap.dart';
import 'features/audio/data/quran_audio_handler.dart';

Future<void> main() async {
  await bootstrapAndRun(() async {
    WidgetsFlutterBinding.ensureInitialized();
// **Round 5 bugfix**: rotation теперь управляется **через router
// listener**, а не per-widget lifecycle (round 4 не сработал —
// `dispose()` с `unawaited(SystemChrome.setPreferredOrientations)`
// ставил Future после `super.dispose()`, который мог race-condition
// с монтированием следующего route). См.
// `lib/app/orientation_guard.dart` + listener в `app_router.dart`.
//
// Hardcoded initial — `container` ещё не создан, роутер ещё не
// готов. `OrientationGuard._portraitOnly` (default) =
// portrait-only, как и `routerDelegate.currentConfiguration` listener
// в `app_router.dart` применит то же значение при первом push'е.
await SystemChrome.setPreferredOrientations(const [
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // Тёмные иконки статус-бара на светлом фоне.
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFAF7F0),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    // Установить язык системы по умолчанию при первом запуске
    if (prefs.getString('app.languageCode') == null) {
      final sysLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final supported = ['ru', 'en', 'ar'];
      final detected = supported.contains(sysLocale.languageCode)
          ? sysLocale.languageCode
          : 'en';
      await prefs.setString('app.languageCode', detected);
    }

    // Initialize audio_service first — it constructs the handler and
    // wires it to the OS-level media session + foreground service. The
    // handler is a no-arg singleton at this point; we attach() it to the
    // AudioPlayerController after Riverpod has built the controller.
    //
    // На некоторых OEM (MIUI/XOS/EMUI) `AudioService.init` зависает
    // на этапе bind foreground service / создания MediaSession —
    // обычно из-за отказа `POST_NOTIFICATIONS` runtime-разрешения
    // (Android 13+) или «залипшего» канала нотификации. Чтобы
    // приложение всё равно запускалось (in-app playback работает,
    // просто без OS-level нотификации / lock-screen контролов),
    // оборачиваем init в `Future.timeout(8s)` и в fallback собираем
    // обычный `QuranAudioHandler` без `AudioService.init`. См. issue
    // `audio_service` #1128 на GitHub.
    //
    // Helper вынесен в функцию, чтобы Dart analyzer мог статически
    // доказать «definitely assigned» (иначе `final QuranAudioHandler
    // handler` в try/catch ругается «might already be assigned» —
    // см. kernel_snapshot_program failed... handler).
    final handler = await _initAudioHandler();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        quranAudioHandlerProvider.overrideWithValue(handler),
      ],
    );
    // Connect the audio handler to the live AudioPlayerController. Must
    // happen after the container exists (so audioPlayerControllerProvider
    // resolves) but before runApp, so the initial PlaybackState is already
    // broadcast by the time the first widget listens.
    handler.attach(container.read(audioPlayerControllerProvider.notifier));

    // Round 8: seed Quran.com translators на каждом cold start.
    // Вызываем ПОСЛЕ runApp через WidgetsBinding.instance.scheduleFrameCallback,
    // чтобы widget tree был инициализирован. Идемпотентно —
    // findByQuranComId проверяет наличие. Раньше это было в
    // bulk-install bootstrap, но этот путь срабатывает только при
    // cold install — на existing installations bootstrap screen
    // пропускается (isReady=true) и translators не доходили до
    // existing devices.
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const QuranApp(),
      ),
    );

    // После runApp, но до первого frame. scheduleFrameCallback
    // срабатывает после первого build/layout.
    WidgetsBinding.instance.scheduleFrameCallback((_) {
      Future.microtask(() async {
        try {
          final bootstrapper = container.read(contentBootstrapperProvider);
          await bootstrapper.seedTranslators();
          // Инвалидируем кэш translatorsListProvider чтобы UI увидел
          // новых translators (Кулиев/Quran.com + Минвакф + Абу Адель).
          // Без этого UI продолжал бы показывать старый snapshot
          // с 2 переводами из pre-seed БД.
          container.read(translatorsListRefreshProvider.notifier).state++;
        } catch (e, st) {
          developer.log(
            'seedTranslators failed: $e',
            name: 'main',
            error: e,
            stackTrace: st,
          );
        }
      });
    });
  });
}

/// Изолирует try/catch/timeout от [AudioService.init] в отдельной
/// функции — иначе Dart analyzer не может доказать «definitely
/// assigned» для `final handler` в вызывающем коде (см. ошибки
/// `Final variable might already be assigned`).
///
/// Возвращает валидный [QuranAudioHandler] **всегда** — либо
/// полноценный foreground-aware (как хочет `audio_service`),
/// либо headless-инстанс без OS-уровня (на устройствах, где
/// `AudioService.init` зависает).
Future<QuranAudioHandler> _initAudioHandler() async {
  try {
    return await AudioService.init<QuranAudioHandler>(
      builder: QuranAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.quran.app.quran_app.channel.audio',
        androidNotificationChannelName: 'Quran playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    ).timeout(
      const Duration(seconds: 8),
    );
  } on TimeoutException {
    developer.log(
      'AudioService.init timed out — falling back to headless handler '
      '(no OS-level notification / lock-screen controls). '
      'Foreground playback is disabled on this device.',
      name: 'QuranAudio',
    );
    return QuranAudioHandler();
  } catch (e, st) {
    developer.log(
      'AudioService.init failed: $e\n$st\n'
      'Continuing with headless handler (in-app playback only).',
      name: 'QuranAudio',
      error: e,
      stackTrace: st,
    );
    return QuranAudioHandler();
  }
}
