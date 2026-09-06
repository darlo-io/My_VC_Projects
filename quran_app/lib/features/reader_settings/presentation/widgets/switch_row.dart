import 'package:flutter/material.dart';

import '../reader_palette.dart';

/// Строка с лейблом и Switch. Опциональный `badge` рендерится
/// справа от label (например, "beta"-метка).
///
/// Цвета берёт из [ReaderPalette] экрана настроек (раньше —
/// светлая `AppColors`, нечитаемая на тёмных темах).
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.palette,
    this.badge,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ReaderPalette palette;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: palette.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 10,
                        color: palette.gold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: palette.gold,
          ),
        ],
      ),
    );
  }
}
