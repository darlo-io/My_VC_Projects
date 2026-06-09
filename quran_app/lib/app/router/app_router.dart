import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audio/presentation/listen_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../features/bookmarks/presentation/bookmarks_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/learning/presentation/learn_screen.dart';
import '../../features/onboarding/presentation/language_picker_screen.dart';
import '../../features/quran/presentation/reader_screen.dart';
import '../../features/quran/presentation/surah_list_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/tasbih/presentation/tasbih_screen.dart';
import '../../features/test/presentation/quiz_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Если контент ещё не загружен — сначала идём на онбординг
      final ready = ref.read(contentReadyProvider);
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isBootstrap = state.matchedLocation == '/bootstrap';

      return ready.when(
        data: (ok) {
          if (!ok && !isBootstrap) return '/bootstrap';
          if (ok && (isOnboarding || isBootstrap)) return '/';
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
        path: '/listen',
        builder: (_, _) => const ListenScreen(),
      ),
      GoRoute(
        path: '/learn',
        builder: (_, _) => const LearnScreen(),
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
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen<AsyncValue<bool>>(contentReadyProvider, (_, _) {
      notifyListeners();
    });
    ref.listen<String?>(languageProvider, (_, _) => notifyListeners());
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    setState(() {
      _statusKey = 'bootstrapLocalLoading';
      _failed = false;
    });
    try {
      await ref.read(contentReadyProvider.notifier).bootstrap();
      if (!mounted) return;
      final firstLaunch =
          !ref.read(appPreferencesProvider).isFirstLaunchDone;
      if (firstLaunch) {
        await ref.read(appPreferencesProvider).setFirstLaunchDone(true);
        if (mounted) context.go('/onboarding');
      } else {
        if (mounted) context.go('/');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusKey = 'bootstrapFailed';
        _failed = true;
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
                  color: Color(0xFFB7A98F),
                  fontSize: 14,
                ),
              ),
              if (_failed) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _run,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
