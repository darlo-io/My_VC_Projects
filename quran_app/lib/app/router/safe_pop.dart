import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Безопасные операции навигации для GoRouter, которые **не** бросают
/// `GoError: There is nothing to pop` / `Null check operator used on a
/// null value` на root-routes (открытых через `context.go(...)`).
///
/// **Важно**: `GoRouter.canPop()` возвращает `true` всегда, если
/// router знает о текущем location — но **это не** означает, что
/// у root-route есть parent-Navigator. Безопасный способ — найти
/// ближайший `NavigatorState` в дереве: если он null, у текущего
/// location нет стека и `pop()` упадёт в `GoRouterDelegate`
/// (`_findCurrentNavigator:114`). В этом случае делаем
/// `go(fallbackRoute)`.

/// `pop` или `go('/')`, если родительский стек пуст.
void safePop(BuildContext context) => safePopTo(context, '/');

/// `pop` или `go(fallbackRoute)`, если родительский стек пуст.
void safePopTo(BuildContext context, String fallbackRoute) {
  final router = GoRouter.of(context);
  // `Navigator.maybeOf` возвращает null, если в текущем
  // Element-дереве нет вышестоящего Navigator (root-route,
  // например `/listen` / `/tasbih` / `/settings` / `/profile`).
  // В этом случае `pop()` через `GoRouterDelegate` бросил бы
  // `Null check operator` — fallback в `go()`.
  final hasNav =
      Navigator.maybeOf(context, rootNavigator: false) != null ||
          Navigator.maybeOf(context, rootNavigator: true) != null;
  if (hasNav) {
    router.pop();
  } else {
    router.go(fallbackRoute);
  }
}

/// `push`, только если родительский стек есть (иначе fallback через `go`).
void safePush(BuildContext context, String location) {
  final router = GoRouter.of(context);
  final hasNav =
      Navigator.maybeOf(context, rootNavigator: false) != null ||
          Navigator.maybeOf(context, rootNavigator: true) != null;
  if (hasNav) {
    router.push(location);
  } else {
    router.go(location);
  }
}
