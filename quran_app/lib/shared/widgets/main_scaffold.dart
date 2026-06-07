import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/audio/presentation/widgets/mini_player.dart';
import '../widgets/ornaments.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.child, super.key});

  final Widget child;

  static const _routes = ['/', '/read', '/search', '/bookmarks', '/profile'];
  static const _icons = [
    Icons.home_outlined,
    Icons.menu_book_outlined,
    Icons.search,
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
    final location =
        GoRouterState.of(context).matchedLocation;
    final index = _indexFor(location);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ArabesqueBackground(opacity: 0.04)),
          child,
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundDeep,
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderSubtle,
                    width: 0.5,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: List.generate(_routes.length, (i) {
                  final selected = i == index;
                  return Expanded(
                    child: InkWell(
                      onTap: () => context.go(_routes[i]),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _icons[i],
                              color: selected
                                  ? AppColors.gold
                                  : AppColors.textTertiary,
                              size: 24,
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
                                    ? AppColors.gold
                                    : AppColors.textTertiary,
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
    final loc = Localizations.localeOf(context);
    final isRu = loc.languageCode == 'ru';
    switch (index) {
      case 0:
        return isRu ? 'Главная' : 'Home';
      case 1:
        return isRu ? 'Читать' : 'Read';
      case 2:
        return isRu ? 'Поиск' : 'Search';
      case 3:
        return isRu ? 'Закладки' : 'Bookmarks';
      case 4:
        return isRu ? 'Профиль' : 'Profile';
    }
    return '';
  }
}
