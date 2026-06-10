import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'common_widgets.dart';

/// Заголовок экрана в стиле приложения с подзаголовком.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.showTitle = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;

  /// Показывать ли [title] и [subtitle]. По умолчанию `true`.
  /// Используется на экранах, где заголовок не нужен (например,
  /// Mushaf — заголовок суры рисует `SurahTitleFrame` поверх
  /// Mushaf-рамки, а отдельный «Читать» сверху был избыточен).
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(
          children: [
            if (onBack != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  iconSize: 18,
                  onTap: onBack,
                ),
              )
            else
              const SizedBox(width: 8),
            if (showTitle)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              const Spacer(),
            ...actions,
          ],
        ),
      ),
    );
  }
}
