import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Универсальная строка слайдера: label слева, value справа,
/// Slider ниже на всю ширину.
///
/// Не использует [ValueKey] на Slider — внешний код управляет
/// ребилдом через `setState` (см. [ReaderDisplaySettingsScreen]).
class SliderRow extends StatelessWidget {
  const SliderRow({super.key, 
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.valueLabel,
    this.inactiveColor,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String valueLabel;

  /// Цвет «дорожки» слайдера. По умолчанию — `borderSubtle`.
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            inactiveTrackColor: inactiveColor ?? AppColors.borderSubtle,
            activeTrackColor: AppColors.gold,
            thumbColor: AppColors.gold,
            overlayColor: AppColors.gold.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
