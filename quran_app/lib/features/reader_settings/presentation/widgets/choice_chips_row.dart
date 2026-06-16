import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Горизонтальный ряд mutually-exclusive chips. Используется для
/// выбора `fontFamily`, `themeVariant` и т.п. — там, где нужно
/// выбрать **одно** из N значений.
///
/// Не использует [ValueKey] — внешний код управляет ребилдом
/// через `setState`.
class ChoiceChipsRow<T> extends StatelessWidget {
  const ChoiceChipsRow({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.fullWidth = false,
  });

  /// Пары `(value, label)`. Порядок отображается как есть.
  final List<({T value, String label})> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final children = options.map((opt) {
      final isSel = opt.value == selected;
      final chip = Material(
        color: isSel ? AppColors.gold : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(opt.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Center(
              child: Text(
                opt.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSel
                      ? AppColors.backgroundDeep
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      );
      return fullWidth ? Expanded(child: chip) : chip;
    }).toList();
    if (fullWidth) {
      return Row(children: _spaced(children, gap: 8));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }

  List<Widget> _spaced(List<Widget> children, {double gap = 8}) {
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      out.add(children[i]);
      if (i != children.length - 1) {
        out.add(SizedBox(width: gap));
      }
    }
    return out;
  }
}
