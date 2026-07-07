import 'dart:async';
import 'dart:developer' as developer;


import 'package:flutter_skill/flutter_skill.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'features/audio/data/quran_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
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

  // Глобальный обработчик ошибок Flutter. По умолчанию в
  // debug-режиме показывается красный экран, в release — тихо
  // логируется. Нам важно **видеть** исключение в `flutter run`
  // и в `adb logcat` — иначе, как сейчас, непонятно, почему
  // Reader выкидывает в Home при смене reading-mode.
  FlutterError.onError = (details) {
    developer.log(
      'FlutterError: ${details.exceptionAsString()}',
      name: 'Flutter',
      error: details.exception,
      stackTrace: details.stack,
    );
    // Также отдаём в дефолтный presentation (красный экран /
    // console), чтобы не потерять UX дев-режима.
    FlutterError.presentError(details);
  };
  // `PlatformDispatcher.instance.onError` срабатывает только
  // в release-режиме (в debug FlutterError.onError уже ловит всё).
  // Прописываем его явно — пригодится при профилировании.
  // (Импорт `dart:ui` явно НЕ нужен — PlatformDispatcher в
  // глобальном скоупе Flutter SDK.)

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
  FlutterSkillBinding.ensureInitialized();	

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const QuranApp(),
    ),
  );
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
