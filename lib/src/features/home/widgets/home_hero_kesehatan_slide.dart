import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/health_score.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';

/// ---------------------------------------------------------------------------
/// Slide 3 — Kesehatan finansial
/// ---------------------------------------------------------------------------
class KesehatanSlide extends StatelessWidget {
  const KesehatanSlide({super.key, required this.score});
  final HealthScore score;

  // Tiers align with `verdictFor` (>=65 sehat, >=50 cukup, <50 below).
  Color _stateColor() {
    if (score.score >= 65) return FtColors.healthOk;
    if (score.score >= 50) return FtColors.healthWarn;
    return FtColors.healthBad;
  }

  String _summary() {
    final weakest = score.weakestFactor;
    if (weakest == null) return 'Data belum cukup untuk membaca pola.';
    return '${weakest.label} paling perlu perhatian.';
  }

  @override
  Widget build(BuildContext context) {
    final color = _stateColor();
    return FtCard(
      backgroundColor: FtColors.tileFor(FtColors.catEntertainment),
      heroTag: 'ft-kesehatan-hero',
      onTap: () => context.push('/health'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Kesehatan Finansial'),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CustomPaint(
                    painter: _HealthRingPainter(
                      value: score.score / 100,
                      color: color,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${score.score}',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: color,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            '/ 100',
                            style: TextStyle(
                              color: FtColors.ink3,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        score.verdict,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 17,
                              height: 1.2,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _summary(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: FtColors.ink2,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthRingPainter extends CustomPainter {
  _HealthRingPainter({required this.value, required this.color});

  final double value;
  final Color color;
  static const double _thickness = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - _thickness) / 2,
    );
    final track = Paint()
      ..color = FtColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = _thickness;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (value <= 0) return;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(_HealthRingPainter old) =>
      old.value != value || old.color != color;
}
