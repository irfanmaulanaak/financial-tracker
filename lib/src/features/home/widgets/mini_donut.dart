import 'dart:math';

import 'package:flutter/material.dart';

import '../../../theme.dart';

class DonutSegment {
  final double value;
  final Color color;
  const DonutSegment({required this.value, required this.color});
}

/// Lightweight donut painter for the HomeB hero. Doesn't pull `fl_chart` so
/// it stays cheap to render at small sizes (40-100 px).
class MiniDonut extends StatelessWidget {
  const MiniDonut({
    super.key,
    required this.segments,
    this.size = 92,
    this.thickness = 11,
    this.gap = 1.5,
  });

  final List<DonutSegment> segments;
  final double size;
  final double thickness;

  /// Angular gap between sectors in radians.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          segments: segments,
          thickness: thickness,
          gap: gap,
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.thickness,
    required this.gap,
  });
  final List<DonutSegment> segments;
  final double thickness;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (a, b) => a + b.value);
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - thickness) / 2,
    );
    final track = Paint()
      ..color = FtColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(rect.center, rect.width / 2, track);

    if (total <= 0) return;
    var start = -pi / 2;
    final gapAdjusted = segments.length > 1 ? gap : 0.0;
    for (final s in segments) {
      final sweep = (s.value / total) * (2 * pi) - gapAdjusted;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + gapAdjusted;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments ||
      old.thickness != thickness ||
      old.gap != gap;
}
