import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../l10n/generated/app_localizations.dart';

class QuranApp extends ConsumerWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Round 4 bugfix: rotation теперь управляется **напрямую** из
    // `ReaderScreen.initState`/`dispose` через `SystemChrome
    // .setPreferredOrientations(...)`. Round 3 approach через
    // Riverpod `ref.listen` + `addPostFrameCallback` имел слишком
    // много async-step'ов и иногда не срабатывал (user feedback
    // 2026-07-21: «поворот работает на всех экранах»).
    //
    // Текущий подход:
    //   1. `main.dart` ставит `portrait-only` при старте.
    //   2. `ReaderScreen.initState` через `addPostFrameCallback`
    //      вызывает `setPreferredOrientations(_allOrientations)`.
    //   3. `ReaderScreen.dispose` вызывает
    //      `setPreferredOrientations(_portraitOnly)`.
    //
    // Прямой, синхронный (с `await` для надёжности), без посредников.

    final router = ref.watch(routerProvider);
    final languageCode = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'Quran',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: router,
      locale: _resolveLocale(languageCode),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
        Locale('ar'),
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  Locale? _resolveLocale(String? code) {
    if (code == null) return null;
    return Locale(code);
  }
}
