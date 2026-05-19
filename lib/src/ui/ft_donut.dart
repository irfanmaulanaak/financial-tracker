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
///
/// Segments sweep from zero into place over [animationDuration] on first
/// build and tween toward new values when the data changes.
class FtDonut extends StatefulWidget {
  const FtDonut({
    super.key,
    required this.segments,
    this.size = 130,
    this.thickness = 16,
    this.centerLabel,
    this.centerValue,
    this.trackColor,
    this.animationDuration = const Duration(milliseconds: 700),
  });

  final List<FtDonutSegment> segments;
  final double size;
  final double thickness;
  final String? centerLabel;
  final String? centerValue;
  final Color? trackColor;
  final Duration animationDuration;

  @override
  State<FtDonut> createState() => _FtDonutState();
}

class _FtDonutState extends State<FtDonut> {
  double _start = 0;
  double _target = 1;

  @override
  void initState() {
    super.initState();
    // Schedule the sweep after first paint so the animation runs.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _start = 0;
        _target = 1;
      });
    });
  }

  @override
  void didUpdateWidget(covariant FtDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segments != widget.segments) {
      // On data change, snap to current 1.0 then sweep again. Visually this
      // reads as the new values being drawn in.
      _start = 0;
      _target = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showCenter = widget.centerLabel != null || widget.centerValue != null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: _start, end: _target),
        duration: reduceMotion ? Duration.zero : widget.animationDuration,
        curve: Curves.easeOutCubic,
        builder: (_, t, child) {
          return CustomPaint(
            painter: _DonutPainter(
              segments: widget.segments,
              thickness: widget.thickness,
              trackColor: widget.trackColor ?? FtColors.line,
              progress: t,
            ),
            child: child,
          );
        },
        child: showCenter
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.centerLabel != null)
                      Text(
                        widget.centerLabel!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1.4,
                          color: FtColors.ink3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (widget.centerValue != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.centerValue!,
                        style: TextStyle(
                          fontSize: widget.size * 0.16,
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
    required this.progress,
  });

  final List<FtDonutSegment> segments;
  final double thickness;
  final Color trackColor;
  final double progress;

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

    final total = segments.fold<double>(0, (s, x) => s + x.value);
    if (total <= 0) return;

    var start = -math.pi / 2;
    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final fullSweep = (seg.value / total) * math.pi * 2;
      final sweep = fullSweep * progress.clamp(0.0, 1.0);
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += fullSweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.segments != segments ||
      old.thickness != thickness ||
      old.trackColor != trackColor ||
      old.progress != progress;
}
