import 'package:flutter/material.dart';

import 'progress_ring.dart';

/// Маленький ring с номером джуза и процентом. Используется в
/// строке «Progress по джузам» (30 штук в горизонтальный scroll).
///
/// На референсе `docs/images/statistic.png` это 6 circles в строке
/// с подписями "100%", "100%", "75%", "50%", "25%", "0%" под
/// каждым. Здесь мы делаем то же для всех 30 джузов в
/// horizontal-scroll, чтобы юзер мог промотать до конца.
///
/// [size] по умолчанию 56 — компактнее, чем hero-ring, чтобы
/// поместилось 6-8 штук на одном экране.
class JuzProgressCircle extends StatelessWidget {
  const JuzProgressCircle({
    required this.juz,
    required this.progress,
    required this.label,
    this.size = 56,
  });

  final int juz; // 1..30
  final double progress; // [0.0, 1.0]
  final String label; // e.g. "100%", "75%", "0%"
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProgressRing(
            progress: progress,
            value: '$juz',
            color: progress >= 1.0
                ? const Color(0xFF4CAF82) // success green — finished
                : progress > 0
                    ? const Color(0xFFD4A84A) // gold — in progress
                    : const Color(0xFF7E7563), // muted — not started
            trackColor: const Color(0x1AD4A84A),
            strokeWidth: 3,
            size: size,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: progress >= 1.0
                  ? const Color(0xFF4CAF82)
                  : const Color(0xFFB7A98F),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
