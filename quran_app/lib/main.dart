import 'dart:developer' as developer;

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
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF051410),
      systemNavigationBarIconBrightness: Brightness.light,
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
  final handler = await AudioService.init<QuranAudioHandler>(
    builder: QuranAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.quran.app.quran_app.channel.audio',
      androidNotificationChannelName: 'Quran playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

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

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const QuranApp(),
    ),
  );
}
