import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import 'home_formatters.dart';

/// ---------------------------------------------------------------------------
/// Slide 2 — Pengeluaran vs Gaji
/// ---------------------------------------------------------------------------
class RatioSlide extends StatelessWidget {
  const RatioSlide({super.key, required this.spend, required this.gajiIncome});

  final int spend;
  final int gajiIncome;

  @override
  Widget build(BuildContext context) {
    final hasGaji = gajiIncome > 0;
    final spendShare = !hasGaji
        ? (spend > 0 ? 1.0 : 0.0)
        : (spend / gajiIncome).clamp(0.0, 1.0);
    final overBudget = hasGaji && spend > gajiIncome;
    final pct = hasGaji ? (spend / gajiIncome * 100).round() : 0;

    return FtCard(
      backgroundColor: FtColors.tileFor(FtColors.catBills),
      onTap: () => context.push('/incomes'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: Eyebrow('Rasio Pengeluaran · Gaji')),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 116,
                  height: 116,
                  child: CustomPaint(
                    painter: _RatioRingPainter(
                      spendShare: spendShare,
                      overBudget: overBudget,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasGaji ? '$pct%' : '–',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: overBudget
                                  ? FtColors.danger
                                  : FtColors.ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            hasGaji ? 'Gaji terpakai' : 'belum ada gaji',
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
                      _Legend(
                        color: FtColors.danger,
                        label: 'Pengeluaran',
                        value: compactMoney(spend),
                      ),
                      const SizedBox(height: 10),
                      _Legend(
                        color: FtColors.moss,
                        label: 'Gaji',
                        value: hasGaji ? compactMoney(gajiIncome) : 'Catat gaji',
                      ),
                      if (!hasGaji) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tap untuk catat gaji pertama.',
                          style: TextStyle(
                            color: FtColors.ink3,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                      if (overBudget) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Melampaui gaji siklus ini.',
                          style: TextStyle(
                            color: FtColors.danger,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 10,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Two-arc ring: red arc for expense share, green arc fills the remainder.
/// When [overBudget] is true the red arc covers the full circle (the green
/// disappears).
class _RatioRingPainter extends CustomPainter {
  _RatioRingPainter({required this.spendShare, required this.overBudget});

  final double spendShare;
  final bool overBudget;
  static const double _thickness = 14;

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

    if (overBudget) {
      final red = Paint()
        ..color = FtColors.danger
        ..style = PaintingStyle.stroke
        ..strokeWidth = _thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, red);
      return;
    }

    // Green underlay for the full circle (income capacity).
    final green = Paint()
      ..color = FtColors.moss
      ..style = PaintingStyle.stroke
      ..strokeWidth = _thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, green);

    if (spendShare > 0) {
      final red = Paint()
        ..color = FtColors.danger
        ..style = PaintingStyle.stroke
        ..strokeWidth = _thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * spendShare,
        false,
        red,
      );
    }
  }

  @override
  bool shouldRepaint(_RatioRingPainter old) =>
      old.spendShare != spendShare || old.overBudget != overBudget;
}
