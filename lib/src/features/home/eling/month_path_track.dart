import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme.dart';

/// A gentle arc across [width], re-based so dot `i` of [monthsTotal] sits at
/// `i / monthsTotal` — the small-scale cousin of `TrackGeometry` used for
/// installment plans (DESIGN.md section 6, item 2).
class MonthGeo {
  MonthGeo(this.width, {this.baseY = 34, this.bowHeight = 14})
      : x0 = 14,
        x1 = math.max(14, width - 14);
  final double width;
  final double baseY, bowHeight;
  final double x0, x1;

  Offset pointAt(double f) {
    final x = x0 + (x1 - x0) * f;
    final y = baseY - bowHeight * 4 * f * (1 - f);
    return Offset(x, y);
  }
}

/// Paints the track line (light full-length, accent up to [paidFraction])
/// and a dot per month. Shared by `MonthPathEling` and [MonthPathMini].
class MonthTrackPainter extends CustomPainter {
  MonthTrackPainter({
    required this.geo,
    required this.monthsTotal,
    required this.paidFraction,
    required this.accent,
    required this.light,
    required this.surface,
    this.dotRadius = 3.6,
  });

  final MonthGeo geo;
  final int monthsTotal;
  final double paidFraction;
  final Color accent, light, surface;
  final double dotRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final full = Path();
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final p = geo.pointAt(i / steps);
      if (i == 0) {
        full.moveTo(p.dx, p.dy);
      } else {
        full.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(full, line..color = light);
    if (paidFraction > 0.002) {
      final filled = Path();
      for (var i = 0; i <= steps; i++) {
        final f = (i / steps) * paidFraction;
        final p = geo.pointAt(f);
        if (i == 0) {
          filled.moveTo(p.dx, p.dy);
        } else {
          filled.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        filled,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    final start = geo.pointAt(0);
    canvas.drawCircle(start, 5, Paint()..color = accent);
    for (var i = 1; i <= monthsTotal; i++) {
      final on = i <= paidFraction * monthsTotal + 1e-6;
      final p = geo.pointAt(i / monthsTotal);
      canvas.drawCircle(p, dotRadius, Paint()..color = on ? accent : surface);
      canvas.drawCircle(
        p,
        dotRadius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = on ? accent : light,
      );
    }
  }

  @override
  bool shouldRepaint(MonthTrackPainter old) =>
      old.paidFraction != paidFraction ||
      old.monthsTotal != monthsTotal ||
      old.accent != accent;
}

/// Static, animation-free dots-only strip (~84px wide) for the Utang tab's
/// inline installment list (DESIGN.md section 6, item 2).
class MonthPathMini extends StatelessWidget {
  const MonthPathMini({
    super.key,
    required this.monthsTotal,
    required this.monthsPaid,
    this.width = 84,
  });

  final int monthsTotal;
  final int monthsPaid;
  final double width;

  @override
  Widget build(BuildContext context) {
    final total = monthsTotal < 1 ? 1 : monthsTotal;
    final geo = MonthGeo(width, baseY: 10, bowHeight: 3);
    return SizedBox(
      width: width,
      height: 14,
      child: CustomPaint(
        painter: MonthTrackPainter(
          geo: geo,
          monthsTotal: total,
          paidFraction: (monthsPaid / total).clamp(0.0, 1.0),
          accent: FtColors.clay,
          light: Color.alphaBlend(
              FtColors.clay.withValues(alpha: 0.22), FtColors.surface),
          surface: FtColors.surface,
          dotRadius: 2.6,
        ),
      ),
    );
  }
}
