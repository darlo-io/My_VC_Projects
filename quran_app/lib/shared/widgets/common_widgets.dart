import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'ornaments.dart';

/// Полупрозрачная «золотая» кнопка-таблетка (как "Продолжить" на главной).
class GoldPillButton extends StatelessWidget {
  const GoldPillButton({
    required this.label,
    this.icon = Icons.chevron_right,
    this.onPressed,
    this.iconSize = 22,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnGold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: AppColors.textOnGold, size: iconSize),
            ],
          ),
        ),
      ),
    );
  }
}

/// Большая квадратная карточка-категория (Читать / Слушать / и т.д.) с иконкой.
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    required this.icon,
    required this.title,
    this.gradient,
    this.onTap,
    this.iconSize = 44,
    super.key,
  });

  final IconData icon;
  final String title;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: gradient,
            color: gradient == null ? AppColors.surface : null,
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: ArabesqueBackground(opacity: 0.08)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GoldIconBadge(
                      icon: icon,
                      size: 72,
                      iconSize: iconSize,
                      background: Colors.transparent,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.gold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Маленькая круглая кнопка-иконка (как в углу шапки).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    this.onTap,
    this.size = 44,
    this.iconSize = 22,
    this.background = AppColors.surface,
    this.borderColor = AppColors.borderSubtle,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color background;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, color: AppColors.gold, size: iconSize),
        ),
      ),
    );
  }
}

/// Полупрозрачная карточка с золотой тонкой рамкой и внутренним свечением.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: ArabesqueBackground(opacity: 0.05)),
          child,
        ],
      ),
    );
    // Material ancestor is required for descendants like [Slider],
    // [InkWell], and [DropdownButton] even when this card itself
    // does not have a tap handler. Always wrap in transparent Material.
    if (onTap == null) {
      return Material(color: Colors.transparent, child: body);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: body,
      ),
    );
  }
}
