import 'package:flutter/material.dart';

import '../reader_palette.dart';

/// Универсальная строка слайдера: label слева, value справа,
/// Slider ниже на всю ширину.
///
/// Цвета берёт из [ReaderPalette] экрана настроек — иначе на
/// тёмных/sepia-темах лейблы рендерились светлой палитрой
/// `AppColors` и сливались с тёмной карточкой.
class SliderRow extends StatelessWidget {
  const SliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.valueLabel,
    required this.palette,
    this.inactiveColor,
    this.onChangeEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String valueLabel;
  final ReaderPalette palette;

  /// Цвет «дорожки» слайдера. По умолчанию — `palette.border`.
  final Color? inactiveColor;

  /// Вызывается один раз при отпускании thumb'а. Для непрерывных
  /// настроек здесь персистят (дорогое platform-channel write),
  /// а в [onChanged] обновляют только in-memory state.
  final ValueChanged<double>? onChangeEnd;

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
                style: TextStyle(
                  fontSize: 13,
                  color: palette.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                fontSize: 13,
                color: palette.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            inactiveTrackColor: inactiveColor ?? palette.border,
            activeTrackColor: palette.gold,
            thumbColor: palette.gold,
            overlayColor: palette.gold.withValues(alpha: 0.15),
            valueIndicatorColor: palette.gold,
            valueIndicatorTextStyle: TextStyle(
              color: palette.background,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            // Скринридер читает «Размер шрифта, 28», а не сырое
            // значение с плавающей точкой.
            semanticFormatterCallback: (_) => '$label: $valueLabel',
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}
