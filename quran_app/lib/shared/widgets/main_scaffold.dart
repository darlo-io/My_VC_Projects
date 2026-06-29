import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/audio/presentation/widgets/mini_player.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/exit_confirm_scope.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.child, super.key});

  final Widget child;

  // Маршруты и иконки нижней навигации — 4 таба как на макете:
// «Главная» / «Тасбих» / «Закладки» / «Профиль».
// (В предыдущей версии было 5 табов с «Читать» и «Поиск», но они
// убраны — на макете только 4.)
static const _routes = ['/', '/tasbih', '/bookmarks', '/profile'];
  static const _icons = [
    Icons.home_outlined,
    Icons.search, // на макете иконка-лупа для таба «Тасбих»
    Icons.bookmark_outline,
    Icons.person_outline,
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _routes.length; i++) {
      if (location == _routes[i]) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Лёгкий кракле-фон под основным контентом — соответствует
          // макету. Светлый, чтобы не «выжигал» текст на главном
          // экране и в Reader.
          Positioned.fill(
            child: CustomPaint(painter: _ScaffoldTexturePainter()),
          ),
          ExitConfirmPopScope(child: child),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          // Светлая навигация — соответствует макету (белый фон,
          // серые иконки, оливковая активная с подсвеченным pill).
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                top: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: List.generate(_routes.length, (i) {
                  final selected = i == index;
                  return Expanded(
                    child: InkWell(
                      onTap: () => context.go(_routes[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.surfaceMuted
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                _icons[i],
                                color: selected
                                    ? AppColors.accentOlive
                                    : AppColors.textSecondary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _label(context, i),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected
                                    ? AppColors.accentOlive
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(BuildContext context, int index) {
    final t = AppLocalizations.of(context);
    switch (index) {
      case 0:
        return t.navHome;
      case 1:
        // Иконка-лупа + подпись «Тасбих» (как на макете). Если в
        // локализации `navTasbih` нет — fallback на `navRead` (тоже
        // ритуальное действие).
        return _labelFor(context, 'tasbih', fallback: t.navRead);
      case 2:
        return t.navBookmarks;
      case 3:
        return t.navProfile;
    }
    return '';
  }

  /// Пытается взять `t.<key>`; если в `AppLocalizations` нет такого
  /// геттера, возвращает `fallback`. Нужно, чтобы добавление нового
  /// таба не падало на старых сгенерированных `.arb`-файлах.
  String _labelFor(BuildContext context, String key, {required String fallback}) {
    try {
      // ignore: avoid_dynamic_calls
      return (AppLocalizations.of(context) as dynamic).navTasbih as String? ??
          fallback;
    } catch (_) {
      return fallback;
    }
  }
}

/// Тонкая кракле-текстура под всем scaffold — едва заметная, как на
/// макете. Не блокирует взаимодействие (IgnorePointer не нужен —
/// краска ничего не перехватывает).
class _ScaffoldTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x08000000)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final rng = _SeededRandom(7);
    for (var i = 0; i < 60; i++) {
      final x = rng.next() * size.width;
      final y = rng.next() * size.height;
      final len = 8 + rng.next() * 28;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + len * 0.7, y + len * 0.7),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeededRandom {
  _SeededRandom(int seed) : _state = seed;
  int _state;
  double next() {
    _state = (_state * 1103515245 + 12345) & 0x7FFFFFFF;
    return _state / 0x7FFFFFFF;
  }
}