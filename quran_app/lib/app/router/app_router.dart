import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audio/presentation/listen_screen.dart';
import '../../features/bookmarks/presentation/bookmarks_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/learning/presentation/learn_hub_screen.dart';
import '../../features/learning/presentation/learn_session_screen.dart';
import '../../features/onboarding/presentation/language_picker_screen.dart';
import '../../features/quran/presentation/reader_screen.dart';
import '../../features/quran/presentation/surah_list_screen.dart';
import '../../features/reader_settings/presentation/reader_display_settings_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/tasbih/presentation/tasbih_screen.dart';
import '../../features/test/presentation/quiz_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../core/content/content_update_service.dart';
import '../../core/theme/app_colors.dart';
import '../orientation_guard.dart';
import '../providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/',
    // DEBUG-ONLY: перехватываем ошибки навигации (в т.ч.
    // `Null check operator` на `_findCurrentNavigator:114`),
    // чтобы UI НЕ падал в «пустой главный экран» при ошибке
    // back-button на root-route без parent-Navigator. В
    // release-режиме логирует в flutter-стдаут; в debug —
    // полный stack trace + возврат на `/` через `go()`.
    errorBuilder: (context, state) {
      debugPrint('[ROUTER] errorBuilder: ${state.error} '
          'uri=${state.uri} matchedLocation=${state.matchedLocation}');
      return const _ErrorFallbackScreen();
    },
    redirect: (context, state) {
      // Если контент ещё не загружен — сначала идём на онбординг
      final ready = ref.read(contentReadyProvider);
      final isBootstrap = state.matchedLocation == '/bootstrap';

      return ready.when(
        data: (ok) {
          if (!ok && !isBootstrap) return '/bootstrap';
          // Только `/bootstrap` редиректим на `/` когда контент
          // готов. `/onboarding` оставляем в покое — онбординг
          // это пользовательский выбор языка, а не гейт к
          // контенту, и пользователь должен иметь возможность
          // вернуться к нему из Settings (`/profile`).
          if (ok && isBootstrap) return '/';
          return null;
        },
        loading: () => isBootstrap ? null : '/bootstrap',
        error: (_, _) => isBootstrap ? null : '/bootstrap',
      );
    },
    refreshListenable: _RouterRefresh(ref),
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const LanguagePickerScreen(),
      ),
      GoRoute(
        path: '/bootstrap',
        builder: (_, _) => const _BootstrapScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (_, state) => const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/read',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: SurahListScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: '/bookmarks',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: BookmarksScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (_, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/reader/:surahId',
        builder: (_, state) => ReaderScreen(
          surahId: int.parse(state.pathParameters['surahId']!),
          initialAyah:
              int.tryParse(state.uri.queryParameters['ayah'] ?? '') ?? 1,
        ),
      ),
      GoRoute(
        // Push из Reader'а (кнопка settings). НЕ лежит в ShellRoute —
        // у него своя AppBar, без bottom-nav. После `Готово` возврат
        // pop'ом назад в Reader с применёнными настройками.
        //
        // URL выбран **вне** namespace `/reader/...` — иначе GoRouter
        // пытается распарсить `display-settings` как `surahId`
        // (radix-10 number) и бросает FormatException. Альтернативы
        // типа `/reader/settings` тоже конфликтуют: для них нужен
        // статический сегмент вместо параметра, и GoRouter 14.x
        // не всегда корректно резолвит порядок.
        path: '/reader-settings/display',
        builder: (_, _) => const ReaderDisplaySettingsScreen(),
      ),
      GoRoute(
        path: '/listen',
        builder: (_, _) => const ListenScreen(),
      ),
      GoRoute(
        path: '/learn',
        builder: (_, _) => const LearnHubScreen(),
      ),
      GoRoute(
        path: '/learn/review',
        builder: (_, _) => const LearnSessionScreen(),
      ),
      GoRoute(
        path: '/test',
        builder: (_, _) => const QuizScreen(),
      ),
      GoRoute(
        path: '/statistics',
        builder: (_, _) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/tasbih',
        builder: (_, _) => const TasbihScreen(),
      ),
    ],
  );

  // **Round 5 bugfix (2026-07-22)**: подписываемся на изменение
  // top-route и применяем SystemChrome.setPreferredOrientations
  // синхронно через [OrientationGuard]. До этого per-widget
  // initState/dispose в ReaderScreen работал ненадёжно — после
  // выхода с Reader ориентация не восстанавливалась на
  // portrait-only. Глобальный listener по top-route решает
  // проблему: route change → orientation change, без
  // зависимости от widget lifecycle.
  //
  // `routerDelegate` (RouterDelegate) IS a Listenable — fires on
  // every route push/pop/replace.
  router.routerDelegate.addListener(() {
    final cfg = router.routerDelegate.currentConfiguration;
    // Top route is the LAST in the match list — for nested routes
    // (ShellRoute etc.) we want the deepest match. Use the last
    // match's matchedLocation if available, fall back to top-level.
    final lastMatch = cfg.matches.isNotEmpty ? cfg.matches.last : null;
    final path = lastMatch?.matchedLocation ?? cfg.uri.path;
    final isReader = path.startsWith('/reader/');
    debugPrint('[ORIENT] route=$path isReader=$isReader');
    globalOrientationGuard.setIsReader(isReader);
  });

  return router;
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    // Слушаем ТОЛЬКО `contentReadyProvider` — он меняет решение
    // `redirect` (идти на /bootstrap или нет). Слушать
    // `languageProvider` НЕ нужно: смена языка НЕ должна
    // re-evaluate redirect'а, и до недавнего времени это был
    // источник проблем — при `setReadingMode` →
    // `appPreferencesProvider.state = …` → `LanguageNotifier`
    // rebuild → `_RouterRefresh.notifyListeners()` → go_router
    // пере-обрабатывает текущий путь `/reader/:id` и в каком-то
    // edge-case'е выкидывал пользователя на Home. Удаление
    // listener'а решает проблему без потери функциональности
    // (локализация MaterialApp обновляется отдельно).
    ref.listen<AsyncValue<bool>>(contentReadyProvider, (_, _) {
      notifyListeners();
    });
  }
}

class _BootstrapScreen extends ConsumerStatefulWidget {
  const _BootstrapScreen();

  @override
  ConsumerState<_BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<_BootstrapScreen> {
  String _statusKey = 'bootstrapChecking';
  bool _failed = false;
  String _errorDetail = '';

  // Подписка на `ContentUpdateService.state` через
  // `addListener` (т.к. это ValueNotifier, а не Provider).
  VoidCallback? _contentUpdateDisposer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
    // Подписываемся на `ContentUpdateService.state` ПОСЛЕ первого
    // frame, чтобы не ловить начальный `idle`. При `completed` —
    // SnackBar "Content is up to date" / "New content available".
    // При `failed` — SnackBar с ошибкой.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final service = ref.read(contentUpdateServiceProvider);
      ContentUpdateState? prev;
      void onChange() {
        if (!mounted) return;
        final next = service.state.value;
        // Skip initial `idle` — он приходит на mount.
        if (prev == null) {
          prev = next;
          return;
        }
        if (next.stage == ContentUpdateStage.completed) {
          final t = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                next.newVersion == null
                    ? t.contentUpdateUpToDate
                    : t.contentUpdateAvailable(next.newVersion!),
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (next.stage == ContentUpdateStage.failed) {
          final t = AppLocalizations.of(context);
          final isIntegrity =
              (next.message ?? '').startsWith('integrity:');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isIntegrity
                    ? '${t.contentUpdateIntegrity}\n${next.message ?? ''}'
                    : '${t.contentUpdateFailed}\n${next.message ?? ''}',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 8),
            ),
          );
        }
        prev = next;
      }

      service.state.addListener(onChange);
      _contentUpdateDisposer = () {
        service.state.removeListener(onChange);
      };
    });
  }

  @override
  void dispose() {
    _contentUpdateDisposer?.call();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _statusKey = 'bootstrapLocalLoading';
      _failed = false;
      _errorDetail = '';
    });
    try {
      await ref.read(contentReadyProvider.notifier).bootstrap();
      if (!mounted) return;
      final firstLaunch =
          !ref.read(appPreferencesProvider).isFirstLaunchDone;
      if (firstLaunch) {
        await ref.read(appPreferencesProvider.notifier).setFirstLaunchDone(true);
        if (mounted) context.go('/onboarding');
      } else {
        if (mounted) context.go('/');
      }
    } catch (e, st) {
      developer.log(
        'bootstrap failed',
        name: '_BootstrapScreen',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() {
        _statusKey = 'bootstrapFailed';
        _failed = true;
        _errorDetail = e.toString();
      });
    }
  }

  String _label(String key) {
    final t = AppLocalizations.of(context);
    switch (key) {
      case 'bootstrapLocalLoading':
        return t.bootstrapLocalLoading;
      case 'bootstrapLocalReady':
        return t.bootstrapLocalReady;
      case 'bootstrapNetworkChecking':
        return t.bootstrapNetworkChecking;
      case 'bootstrapNetworkFailed':
        return t.bootstrapNetworkFailed;
      case 'bootstrapNetworkDone':
        return t.bootstrapNetworkDone;
      case 'bootstrapFailed':
        return t.bootstrapFailed;
      default:
        return t.loading;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: _failed
                    ? const Icon(
                        Icons.error_outline,
                        color: Color(0xFFD05A4F),
                        size: 48,
                      )
                    : const CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 24),
              Text(
                _label(_statusKey),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              if (_failed) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _run,
                  child: Text(AppLocalizations.of(context).retry),
                ),
                if (_errorDetail.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  // `SelectableText` + кнопка копирования — даёт
                  // пользователю вытащить реальный текст ошибки,
                  // чтобы передать разработчику, без перезагрузки
                  // и без `flutter logs`. `maxLines: 4` держит UI
                  // компактным; полный текст — в debug-логе.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SelectableText(
                      _errorDetail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8E8676),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      // Захватываем зависимости от `context` ДО await,
                      // чтобы линтер `use_build_context_synchronously`
                      // не предупреждал о потенциально отсоединённом
                      // дереве виджетов после `Clipboard.setData`.
                      final messenger = ScaffoldMessenger.of(context);
                      final loc = AppLocalizations.of(context);
                      await Clipboard.setData(
                        ClipboardData(text: _errorDetail),
                      );
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(loc.retryCopied),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: Text(
                      AppLocalizations.of(context).copyError,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// DEBUG-ONLY fallback, который показывается через
/// `GoRouter.errorBuilder`. Раньше при ошибке навигации
/// (`Nothing to pop` / `Null check operator` на root-route)
/// показывался «пустой экран». Этот экран логирует ошибку в
/// flutter-стдаут + показывает её текст + кнопку «На главную»,
/// чтобы пользователь не застрял. См. round-9 hotfix.
class _ErrorFallbackScreen extends StatelessWidget {
  const _ErrorFallbackScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation error'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).go('/'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Navigation error',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'An error occurred while navigating. This screen is shown '
                'instead of an empty view to prevent stuck UI.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => GoRouter.of(context).go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
