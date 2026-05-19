import 'package:flutter/material.dart';

import '../theme.dart';

/// Tiny area/line chart for trend hints on the home asset hero card. Mirrors
/// `Sparkline` in `claude-design/design/widgets.jsx`.
///
/// On first build the line draws progressively from left to right over
/// [animationDuration]. On data changes the line is redrawn from zero (a
/// quick re-sweep reads as "the trend updated").
class FtSparkline extends StatefulWidget {
  const FtSparkline({
    super.key,
    required this.data,
    this.color,
    this.fill = true,
    this.width,
    this.height = 28,
    this.strokeWidth = 1.4,
    this.animationDuration = const Duration(milliseconds: 600),
  });

  final List<double> data;
  final Color? color;
  final bool fill;
  final double? width;
  final double height;
  final double strokeWidth;
  final Duration animationDuration;

  @override
  State<FtSparkline> createState() => _FtSparklineState();
}

class _FtSparklineState extends State<FtSparkline> {
  double _target = 1;

  @override
  void didUpdateWidget(covariant FtSparkline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      // Reset to 0 then back to 1 to trigger a new sweep.
      _target = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _target = 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.length < 2) {
      return SizedBox(width: widget.width, height: widget.height);
    }
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _target),
        duration: reduceMotion ? Duration.zero : widget.animationDuration,
        curve: Curves.easeOutCubic,
        builder: (_, t, _) {
          return CustomPaint(
            painter: _SparklinePainter(
              data: widget.data,
              color: widget.color ?? FtColors.moss,
              fill: widget.fill,
              strokeWidth: widget.strokeWidth,
              progress: t,
            ),
          );
        },
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.color,
    required this.fill,
    required this.strokeWidth,
    required this.progress,
  });

  final List<double> data;
  final Color color;
  final bool fill;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = (max - min);
    final norm = range == 0
        ? List.filled(data.length, 0.5)
        : data.map((v) => (v - min) / range).toList();

    final dx = size.width / (data.length - 1);
    final points = <Offset>[
      for (var i = 0; i < norm.length; i++)
        Offset(dx * i, size.height - norm[i] * size.height),
    ];

    // Compute how many full points to draw, plus a fractional interpolation
    // to the next one — produces a smooth left-to-right reveal.
    final p = progress.clamp(0.0, 1.0);
    final endIdx = (p * (points.length - 1));
    final wholeEnd = endIdx.floor();
    final fraction = endIdx - wholeEnd;

    final visiblePoints = <Offset>[
      ...points.take(wholeEnd + 1),
    ];
    if (wholeEnd < points.length - 1 && fraction > 0) {
      final a = points[wholeEnd];
      final b = points[wholeEnd + 1];
      visiblePoints.add(Offset(
        a.dx + (b.dx - a.dx) * fraction,
        a.dy + (b.dy - a.dy) * fraction,
      ));
    }

    if (visiblePoints.length < 2) return;

    if (fill) {
      final fillPath = Path()..moveTo(0, size.height);
      for (final pt in visiblePoints) {
        fillPath.lineTo(pt.dx, pt.dy);
      }
      fillPath.lineTo(visiblePoints.last.dx, size.height);
      fillPath.close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size);
      canvas.drawPath(fillPath, fillPaint);
    }

    final line = Path()..moveTo(visiblePoints.first.dx, visiblePoints.first.dy);
    for (final pt in visiblePoints.skip(1)) {
      line.lineTo(pt.dx, pt.dy);
    }
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(line, stroke);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data ||
      old.color != color ||
      old.fill != fill ||
      old.strokeWidth != strokeWidth ||
      old.progress != progress;
}
