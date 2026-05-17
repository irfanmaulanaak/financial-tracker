import 'package:flutter/material.dart';

import '../theme.dart';

/// Tiny area/line chart for trend hints on the home asset hero card. Mirrors
/// `Sparkline` in `claude-design/design/widgets.jsx`.
class FtSparkline extends StatelessWidget {
  const FtSparkline({
    super.key,
    required this.data,
    this.color,
    this.fill = true,
    this.width,
    this.height = 28,
    this.strokeWidth = 1.4,
  });

  final List<double> data;
  final Color? color;
  final bool fill;
  final double? width;
  final double height;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return SizedBox(width: width, height: height);
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          color: color ?? FtColors.moss,
          fill: fill,
          strokeWidth: strokeWidth,
        ),
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
  });

  final List<double> data;
  final Color color;
  final bool fill;
  final double strokeWidth;

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

    if (fill) {
      final fillPath = Path()..moveTo(0, size.height);
      for (final p in points) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(size.width, size.height);
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

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
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
      old.strokeWidth != strokeWidth;
}
