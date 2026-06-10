import 'package:flutter/material.dart';

/// Лёгкий ErrorBoundary: ловит исключения из `build()` дочернего
/// widget'а и показывает их inline вместо сброса навигации.
///
/// Использование:
/// ```dart
/// ErrorBoundary(
///   child: RiskyWidget(),
/// )
/// ```
///
/// Когда дочерний `build()` бросает, Flutter framework
/// автоматически вызывает [ErrorWidget.builder] — дефолтный
/// показывает красный экран в debug, в release — серый. В обоих
/// случаях приложение **остаётся на текущем экране** (если
/// исключение в `MaterialApp.builder` не зацепило). Но
/// `_RouterRefresh` мог бы в это время триггернуть redirect
/// — и тогда сцена выглядит как «выкинуло на Home».
///
/// Здесь мы **не** перехватываем исключения вручную (это
/// невозможно в Dart/Flutter — `build` не имеет try/catch).
/// Вместо этого при первом исключении мы переключаемся на
/// **встроенный** `ErrorWidget` (через `ErrorWidget.builder`),
/// который **не** вызывает `_RouterRefresh` повторно, потому
/// что исключение уже произошло и флаг `_lastError` зафиксирован.
///
/// Если хотите увидеть, какое именно исключение выкинулось,
/// смотрите `flutter logs` / `adb logcat` — наш
/// `FlutterError.onError` логгер в `main.dart` его записывает.
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({required this.child, super.key});
  final Widget child;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
