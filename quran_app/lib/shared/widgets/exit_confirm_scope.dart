import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Показывает диалог подтверждения выхода из приложения.
/// Возвращает `true`, если пользователь подтвердил выход, `false`
/// если отменил.
///
/// Используется в `PopScope` на tab-экранах (`MainScaffold`) —
/// на детальных экранах, зашедших через `context.push`, back уже
/// корректно возвращает на tab-родителя, и диалог там не нужен.
///
/// На Android `SystemNavigator.pop()` завершает activity
/// (аналог finish()) — приложение уходит в background,
/// системный лаунчер остаётся. Это правильное поведение для
/// «выхода из приложения».
Future<bool> showExitConfirmDialog(BuildContext context) async {
  final t = AppLocalizations.of(context);
  final shouldExit = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSubtle, width: 0.5),
        ),
        title: Text(
          t.exitConfirmTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          t.exitConfirmBody,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              t.exitConfirmNo,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              t.exitConfirmYes,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );
  if (shouldExit == true) {
    await SystemNavigator.pop();
    return true;
  }
  return false;
}

/// `PopScope`-обёртка для tab-экранов (`MainScaffold`).
///
/// Поведение: на нажатие «Назад» —
/// 1) если в стеке GoRouter что-то лежит (например, пользователь
///    дошёл сюда через `context.push`) — сначала обычный `pop()`;
/// 2) иначе, если текущий таб — не Home (`/`) — переходим на `/`;
/// 3) иначе (пользователь на Home) — показываем диалог подтверждения
///    выхода.
///
/// Шаг 2 нужен потому, что переключение между табами делается через
/// `context.go(...)` (а не `push`) — стек GoRouter остаётся пустым,
/// и без явной проверки текущего роута пользователь видел бы диалог
/// выхода на любом табе, а не возврат на Home.
class ExitConfirmPopScope extends StatelessWidget {
  const ExitConfirmPopScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final router = GoRouter.of(context);
        // 1) Сначала в стеке.
        if (router.canPop()) {
          router.pop();
          return;
        }
        // 2) Иначе — если мы не на Home, возвращаемся на Home.
        final location = GoRouterState.of(context).matchedLocation;
        if (location != '/') {
          router.go('/');
          return;
        }
        // 3) На Home — диалог.
        await showExitConfirmDialog(context);
      },
      child: child,
    );
  }
}
