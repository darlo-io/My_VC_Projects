import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;

/// Round 5 bugfix (2026-07-22): единый service для управления
/// `SystemChrome.setPreferredOrientations`.
///
/// **Проблема (round 4)**: per-widget `initState`/`dispose` в
/// `ReaderScreen` работал ненадёжно — после выхода с Reader
/// ориентация **не восстанавливалась** на portrait-only. Причина:
/// `unawaited(SystemChrome.setPreferredOrientations(...))` в
/// `dispose()` ставит Future в очередь после `super.dispose()`,
/// который уже убрал widget из дерева. Между этим Future может
/// перехватить следующий route (или Android-Activity не успевает
/// применить изменение до следующего orientation event).
///
/// **Решение**: `OrientationGuard` — единая точка применения
/// ориентаций, привязанная к **top route через go_router**.
/// Когда top route — `/reader/:surahId` → landscape разрешён.
/// Иначе → portrait-only. Не зависит от widget lifecycle.
///
/// API:
/// - `OrientationGuard.setIsReader(bool)` — вызывается из
///   router refresh listener (см. `app_router.dart`).
/// - Применяет SystemChrome синхронно через `setPreferredOrientations`.
class OrientationGuard extends ChangeNotifier {
  static const List<DeviceOrientation> _allOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const List<DeviceOrientation> _portraitOnly = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];

  bool _isReaderActive = false;

  bool get isReaderActive => _isReaderActive;

  /// Вызывается из router refresh listener на каждое изменение
  /// route. Если новое значение отличается от текущего — обновляем
  /// SystemChrome. `notifyListeners()` вызывается в любом случае
  /// (router использует этот notifier для refresh — см.
  /// `refreshListenable` в app_router).
  void setIsReader(bool value) {
    if (_isReaderActive == value) return;
    _isReaderActive = value;
    // Применяем синхронно. На Android это `setRequestedOrientation`
    // через platform channel — сторона выполняется до возврата
    // (хотя Future<void> pending до завершения channel call).
    SystemChrome.setPreferredOrientations(
      value ? _allOrientations : _portraitOnly,
    );
    notifyListeners();
  }
}

/// Global instance — используется router'ом для refresh.
final globalOrientationGuard = OrientationGuard();
