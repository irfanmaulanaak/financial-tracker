import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// One slice of a [FtDonut]: a positive [value] paired with the [color] it
/// should render in. Zero-value segments are skipped at paint time.
class FtDonutSegment {
  const FtDonutSegment({required this.value, required this.color});

  final double value;
  final Color color;
}

/// Pie/donut chart with rounded segment ends and an optional center label.
/// Mirrors `Donut` in `claude-design/design/widgets.jsx`.
class FtDonut extends StatelessWidget {
  const FtDonut({
    super.key,
    required this.segments,
    this.size = 130,
    this.thickness = 16,
    this.centerLabel,
    this.centerValue,
    this.trackColor,
  });

  final List<FtDonutSegment> segments;
  final double size;
  final double thickness;
  final String? centerLabel;
  final String? centerValue;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final showCenter = centerLabel != null || centerValue != null;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          segments: segments,
          thickness: thickness,
          trackColor: trackColor ?? FtColors.line,
        ),
        child: showCenter
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (centerLabel != null)
                      Text(
                        centerLabel!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1.4,
                          color: FtColors.ink3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (centerValue != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        centerValue!,
                        style: TextStyle(
                          fontSize: size * 0.16,
                          fontWeight: FontWeight.w500,
                          color: FtColors.ink,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.segments,
    required this.thickness,
    required this.trackColor,
  });

  final List<FtDonutSegment> segments;
  final double thickness;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - thickness) / 2,
    );

    // Track ring for the empty/zero-data case.
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final total = segments.fold<double>(0, (s, x) => s + x.value);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweep = (seg.value / total) * math.pi * 2;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments ||
      old.thickness != thickness ||
      old.trackColor != trackColor;
}
