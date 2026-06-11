import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Circular progress ring with a centered label. Renders a
/// background track (full circle) plus a foreground arc
/// representing [progress] in `[0.0, 1.0]`. Optionally overlays
/// a small icon at the center (e.g. a Quran stand on the
/// "Quran read" hero card).
///
/// Width / color of the ring come from [strokeWidth] and [color].
/// The label is rendered as bold [value] text followed by an
/// optional [suffix] (e.g. "%" or "X/6236").
///
/// Used by the Statistics screen for the "Quran read %" hero
/// card and for the 30 Juz circles row.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.value,
    this.suffix,
    this.subtitle,
    this.color = const Color(0xFFD4A84A),
    this.trackColor = const Color(0x33D4A84A),
    this.strokeWidth = 10,
    this.size = 180,
    this.icon,
  });

  /// Progress in `[0.0, 1.0]`. Values outside this range are
  /// clamped.
  final double progress;
  final String value;
  final String? suffix;
  final String? subtitle;
  final Color color;
  final Color trackColor;
  final double strokeWidth;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: clamped,
          color: color,
          trackColor: trackColor,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: color.withValues(alpha: 0.6),
                  size: 18,
                ),
                const SizedBox(height: 4),
              ],
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(text: value),
                    if (suffix != null)
                      TextSpan(
                        text: suffix,
                        style: TextStyle(
                          fontSize: size * 0.12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB7A98F),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Background track — full circle (slightly muted).
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      // Foreground arc — start at 12 o'clock and grow clockwise.
      // Flutter's drawArc starts at 0° (3 o'clock); we offset by
      // `-pi / 2` to start at the top.
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
