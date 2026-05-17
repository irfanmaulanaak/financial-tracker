import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Circular progress gauge (0..1 of [value] / [max]). Used as a goal progress
/// ring and a per-factor health-score indicator. Matches `Ring` in
/// `claude-design/design/widgets.jsx`.
class FtRing extends StatelessWidget {
  const FtRing({
    super.key,
    required this.value,
    this.max = 1,
    this.size = 64,
    this.thickness = 6,
    this.color,
    this.trackColor,
    this.child,
  });

  final double value;
  final double max;
  final double size;
  final double thickness;
  final Color? color;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final pct = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: pct,
          thickness: thickness,
          color: color ?? FtColors.ink,
          trackColor: trackColor ?? FtColors.line,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.thickness,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final double thickness;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - thickness) / 2,
    );
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (value <= 0) return;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * value, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.thickness != thickness ||
      old.color != color ||
      old.trackColor != trackColor;
}
