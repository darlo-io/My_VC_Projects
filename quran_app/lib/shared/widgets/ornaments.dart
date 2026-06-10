import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Декоративный уголок (арабеска) в одном из углов рамки.
class OrnamentCorner extends CustomPainter {
  OrnamentCorner({
    required this.corner,
    this.color = AppColors.gold,
    this.strokeWidth = 1.2,
  });

  final Corner corner;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    final r = math.min(w, h) * 0.6;

    switch (corner) {
      case Corner.topLeft:
        path.moveTo(0, h * 0.45);
        path.quadraticBezierTo(0, 0, w * 0.5, 0);
        path.moveTo(0, h * 0.18);
        path.arcToPoint(
          Offset(w * 0.18, 0),
          radius: Radius.circular(r * 0.5),
          clockwise: false,
        );
        break;
      case Corner.topRight:
        path.moveTo(w, h * 0.45);
        path.quadraticBezierTo(w, 0, w * 0.5, 0);
        path.moveTo(w, h * 0.18);
        path.arcToPoint(
          Offset(w * 0.82, 0),
          radius: Radius.circular(r * 0.5),
          clockwise: true,
        );
        break;
      case Corner.bottomLeft:
        path.moveTo(0, h * 0.55);
        path.quadraticBezierTo(0, h, w * 0.5, h);
        path.moveTo(0, h * 0.82);
        path.arcToPoint(
          Offset(w * 0.18, h),
          radius: Radius.circular(r * 0.5),
          clockwise: true,
        );
        break;
      case Corner.bottomRight:
        path.moveTo(w, h * 0.55);
        path.quadraticBezierTo(w, h, w * 0.5, h);
        path.moveTo(w, h * 0.82);
        path.arcToPoint(
          Offset(w * 0.82, h),
          radius: Radius.circular(r * 0.5),
          clockwise: false,
        );
        break;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(OrnamentCorner old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

enum Corner { topLeft, topRight, bottomLeft, bottomRight }

/// Золотая декоративная рамка вокруг контента (используется на странице суры).
class GoldFrame extends StatelessWidget {
  const GoldFrame({
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.borderColor = AppColors.gold,
    this.borderWidth = 1.2,
    this.radius = 24,
    this.showCornerArabesques = false,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color borderColor;
  final double borderWidth;
  final double radius;

  /// Рисовать ли 4 угловые арабески-полумесяца (по одной в
  /// каждом углу рамки). Соответствует референсу
  /// `docs/images/read line by line.png` — на нём Mushaf-рамка
  /// Аль-Фатихи имеет по ornament-звезде в каждом углу.
  /// Default `false` — чтобы не ломать другие места, где
  /// GoldFrame используется без арабесок (читатель сур-лист,
  /// стикер заметок и т.д.).
  final bool showCornerArabesques;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GoldFramePainter(
        color: borderColor,
        strokeWidth: borderWidth,
        radius: radius,
        showCornerArabesques: showCornerArabesques,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _GoldFramePainter extends CustomPainter {
  _GoldFramePainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    this.showCornerArabesques = false,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final bool showCornerArabesques;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(rrect, paint);

    // Внутренняя тонкая рамка
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    const inset = 8.0;
    final innerRect = Rect.fromLTWH(
      strokeWidth / 2 + inset,
      strokeWidth / 2 + inset,
      size.width - strokeWidth - inset * 2,
      size.height - strokeWidth - inset * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(radius - inset)),
      innerPaint,
    );

    // 4 угловые арабески-полумесяца со звёздами. Рисуются
    // только если [showCornerArabesques] включён вызывающим
    // сайтом. Симметрично — в каждом из 4 углов.
    if (showCornerArabesques) {
      _drawCornerArabesque(
        canvas,
        center: const Offset(28, 28),
        paint: paint,
        rotation: 0,
      );
      _drawCornerArabesque(
        canvas,
        center: Offset(size.width - 28, 28),
        paint: paint,
        rotation: math.pi / 2,
      );
      _drawCornerArabesque(
        canvas,
        center: Offset(size.width - 28, size.height - 28),
        paint: paint,
        rotation: math.pi,
      );
      _drawCornerArabesque(
        canvas,
        center: Offset(28, size.height - 28),
        paint: paint,
        rotation: -math.pi / 2,
      );
    }
  }

  /// Маленькая ornament-звезда в углу рамки. На референсе это
  /// 8-конечная звезда с полумесяцем-дугой, повёрнутая так,
  /// чтобы лучи смотрели наружу рамки, а дуга — внутрь.
  void _drawCornerArabesque(
    Canvas canvas, {
    required Offset center,
    required Paint paint,
    required double rotation,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    const outerR = 6.0;
    const innerR = 2.6;
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = i * math.pi / 8 - math.pi / 2;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);

    // Дуга-полумесяц, повёрнутая наружу от угла
    final crescent = Path()
      ..addArc(
        Rect.fromCenter(center: const Offset(0, 8), width: 12, height: 12),
        math.pi,
        math.pi,
      );
    canvas.drawPath(crescent, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GoldFramePainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.showCornerArabesques != showCornerArabesques;
}

/// Заголовок суры в золотой орнаментальной рамке.
///
/// Внешний вид соответствует референсу `docs/images/read line by
/// line.png`: двойная cartouche-рамка с двумя симметричными
/// арабесками-полумесяцами со звёздами по краям (см.
/// `_SurahTitlePainter`).
class SurahTitleFrame extends StatelessWidget {
  const SurahTitleFrame({
    required this.arabicName,
    this.transliteration,
    this.subtitle,
    this.showOrnaments = true,
    super.key,
  });

  final String arabicName;
  final String? transliteration;
  final String? subtitle;
  final bool showOrnaments;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showOrnaments)
            Positioned.fill(
              child: CustomPaint(
                painter: _SurahTitlePainter(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  arabicName,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    fontFamily: 'Amiri',
                    height: 1.2,
                  ),
                ),
                if (transliteration != null || subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [transliteration, subtitle]
                        .whereType<String>()
                        .join(' • '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahTitlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final fill = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    final cy = size.height / 2;
    final w = size.width;

    // Границы cartouche — двойная золотая рамка со скруглёнными
    // углами. Внутренняя рамка — на 8px внутри.
    final rect = Rect.fromLTWH(4, cy - 32, w - 8, 64);
    final outerRRect = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    canvas.drawRRect(outerRRect, paint);
    final innerRect = Rect.fromLTWH(8, cy - 28, w - 16, 56);
    final innerRRect =
        RRect.fromRectAndRadius(innerRect, const Radius.circular(24));
    final innerPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawRRect(innerRRect, innerPaint);

    // Боковые арабески-полумесяцы со звёздами. Симметрично слева и
    // справа от cartouche: внешний полумесяц + 8-конечная звезда
    // внутри. Эти элементы подсмотрены в референсе — придают
    // визуальную «исламскую» идентичность, которой не хватало в
    // предыдущей версии (там были только ornament-линии).
    _drawArabesque(
      canvas,
      center: Offset(20, cy),
      fill: fill,
      paint: paint,
      mirrored: false,
    );
    _drawArabesque(
      canvas,
      center: Offset(w - 20, cy),
      fill: fill,
      paint: paint,
      mirrored: true,
    );
  }

  /// Полумесяц с 8-конечной звездой по центру. В `mirrored: true`
  /// фигура зеркалится по X (для правой стороны).
  void _drawArabesque(
    Canvas canvas, {
    required Offset center,
    required Paint fill,
    required Paint paint,
    required bool mirrored,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (mirrored) canvas.scale(-1, 1);

    // 8-конечная звезда (octagram) — 16 точек, чередующихся
    // между outerR и innerR. Заполняется + обводится для
    // «медальон»-вида.
    final starR = 14.0;
    final starInnerR = starR * 0.45;
    final starPath = Path();
    for (var i = 0; i < 16; i++) {
      final r = i.isEven ? starR : starInnerR;
      final angle = i * math.pi / 8 - math.pi / 2;
      final x = r * math.cos(angle);
      final y = r * math.sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, fill);

    // Маленькая центральная точка-капля
    final centerDot = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 1.5, centerDot);

    // Дуга-полумесяц снаружи звезды (внизу)
    final crescent = Path()
      ..addArc(
        Rect.fromCenter(
          center: const Offset(0, 8),
          width: 26,
          height: 26,
        ),
        math.pi,
        math.pi,
      );
    canvas.drawPath(crescent, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SurahTitlePainter old) => false;
}

/// Круглый значок с золотой рамкой и иконкой внутри (как на главной).
class GoldIconBadge extends StatelessWidget {
  const GoldIconBadge({
    required this.icon,
    this.size = 72,
    this.iconSize = 32,
    this.background,
    this.borderColor = AppColors.gold,
    this.showStarHighlight = false,
    super.key,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? background;
  final Color borderColor;
  final bool showStarHighlight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: background ?? AppColors.surfaceElevated,
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Icon(icon, color: AppColors.gold, size: iconSize),
          ),
          if (showStarHighlight)
            Positioned(
              top: -2,
              right: -2,
              child: CustomPaint(
                size: const Size(20, 20),
                painter: _StarHighlightPainter(),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarHighlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * 0.4;
    const points = 8;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = -math.pi / 2 + i * math.pi / points;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarHighlightPainter old) => false;
}

/// Номер аята в золотой 8-конечной звезде (octagram, как на
/// молитвенных чётках). У каждой вершины — острый луч наружу,
/// что отличает звезду от 8-угольника (`_OctagonPainter` ниже
/// оставлен на случай других нужд).
class AyahNumberBadge extends StatelessWidget {
  const AyahNumberBadge({required this.number, this.size = 36, super.key});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OctagramPainter(),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.backgroundDeep, // Тёмный текст на золотой заливке
              fontWeight: FontWeight.w800,
              fontFamily: 'Amiri',
            ),
          ),
        ),
      ),
    );
  }
}

class _OctagramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2 - 1;
    // Коэффициент 0.45 — это «золотая» пропорция 8-конечной звезды:
    // слишком острые лучи (0.3) визуально сливаются с шумом,
    // слишком тупые (0.6) превращаются в восьмиугольник.
    final innerR = outerR * 0.45;

    // На референсе `docs/images/read line by line.png` номер
    // аята — это **заполненная** золотая 8-звёздная плашка с
    // тёмным цифровым индексом внутри. Outline-only (как было)
    // выглядит «полупустым» по сравнению. Поэтому:
    //   1) fill — сплошной gold
    //   2) stroke — gold-dark поверх (1px) для остроты лучей
    //   3) центральная капля — surface color (как на референсе)
    final fill = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.goldDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < 16; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = i * math.pi / 8 - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_OctagramPainter old) => false;
}

/// Звёздочка закладки (заполненная/пустая).
class BookmarkStar extends StatelessWidget {
  const BookmarkStar({
    required this.filled,
    this.size = 22,
    this.color = AppColors.gold,
    super.key,
  });

  final bool filled;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StarPainter(filled: filled, color: color),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2 - 1;
    final innerR = outerR * 0.42;
    const points = 5;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = -math.pi / 2 + i * math.pi / points;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

/// Тонкая разделительная линия с декоративным центральным элементом.
class OrnateDivider extends StatelessWidget {
  const OrnateDivider({this.color = AppColors.gold, this.opacity = 0.5, super.key});

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: CustomPaint(
        painter: _OrnateDividerPainter(color: color.withValues(alpha: opacity)),
      ),
    );
  }
}

class _OrnateDividerPainter extends CustomPainter {
  _OrnateDividerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final cy = size.height / 2;
    final w = size.width;
    const r = 2.5;

    // Линии по бокам
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(0, cy), Offset(w / 2 - 14, cy), linePaint);
    canvas.drawLine(Offset(w / 2 + 14, cy), Offset(w, cy), linePaint);

    // Центральный ромб
    final diamond = Path()
      ..moveTo(w / 2, cy - r - 1)
      ..lineTo(w / 2 + r + 1, cy)
      ..lineTo(w / 2, cy + r + 1)
      ..lineTo(w / 2 - r - 1, cy)
      ..close();
    canvas.drawPath(diamond, paint);

    // Маленькие точки
    canvas.drawCircle(Offset(w / 2 - 10, cy), 1.0, paint);
    canvas.drawCircle(Offset(w / 2 + 10, cy), 1.0, paint);
  }

  @override
  bool shouldRepaint(_OrnateDividerPainter old) => false;
}

/// Фоновый арабеск-паттерн (полупрозрачные линии).
class ArabesqueBackground extends StatelessWidget {
  const ArabesqueBackground({this.opacity = 0.06, super.key});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ArabesquePainter(opacity: opacity),
        ),
      ),
    );
  }
}

class _ArabesquePainter extends CustomPainter {
  _ArabesquePainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const step = 40.0;
    for (var x = 0.0; x < size.width + step; x += step) {
      for (var y = 0.0; y < size.height + step; y += step) {
        final path = Path();
        const r = step * 0.35;
        path.addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
        // Внутренний крестик
        path.moveTo(x - r * 0.4, y);
        path.lineTo(x + r * 0.4, y);
        path.moveTo(x, y - r * 0.4);
        path.lineTo(x, y + r * 0.4);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ArabesquePainter old) => old.opacity != opacity;
}
