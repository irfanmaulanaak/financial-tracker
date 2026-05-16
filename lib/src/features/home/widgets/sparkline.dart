import 'package:flutter/material.dart';

/// Compact area + line sparkline. Draws the polyline through normalized data
/// points and shades the area below with a soft fill. Used by HomeB's hero.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.data,
    required this.color,
    this.height = 36,
    this.fillOpacity = 0.12,
  });

  final List<double> data;
  final Color color;
  final double height;
  final double fillOpacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          color: color,
          fillOpacity: fillOpacity,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.color,
    required this.fillOpacity,
  });
  final List<double> data;
  final Color color;
  final double fillOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final minV = data.reduce((a, b) => a < b ? a : b);
    final maxV = data.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1e-9 ? 1 : (maxV - minV);
    final dx = size.width / (data.length - 1);
    final points = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(
          i * dx,
          size.height - ((data[i] - minV) / range) * (size.height - 2) - 1,
        ),
    ];
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = color.withValues(alpha: fillOpacity),
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.color != color;
}
