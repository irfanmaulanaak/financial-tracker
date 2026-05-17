import 'package:flutter/material.dart';

import '../theme.dart';

/// One labeled bar in a [FtMonthlyBars] strip — typically a calendar month
/// where [value] is the total spend or contribution that month.
class FtMonthBar {
  const FtMonthBar({
    required this.label,
    required this.value,
    this.color,
    this.highlighted = false,
  });

  final String label;
  final double value;
  final Color? color;
  final bool highlighted;
}

/// Horizontal strip of vertical bars, one per month. Used on goal detail
/// (8-month contribution history) and spend (multi-month comparison).
/// Faded bars share `color`; the highlighted one renders solid.
class FtMonthlyBars extends StatelessWidget {
  const FtMonthlyBars({
    super.key,
    required this.months,
    this.height = 88,
    this.barWidth = 14,
    this.baseColor,
  });

  final List<FtMonthBar> months;
  final double height;
  final double barWidth;
  final Color? baseColor;

  @override
  Widget build(BuildContext context) {
    if (months.isEmpty) return SizedBox(height: height);
    final maxV = months.fold<double>(0, (m, x) => x.value > m ? x.value : m);
    final base = baseColor ?? FtColors.ink;
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final m in months)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _Bar(
                  fraction: maxV == 0 ? 0 : m.value / maxV,
                  color: m.color ?? base,
                  highlighted: m.highlighted,
                  width: barWidth,
                  available: height - 18,
                ),
                const SizedBox(height: 4),
                Text(
                  m.label,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: FtColors.ink3,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.color,
    required this.highlighted,
    required this.width,
    required this.available,
  });

  final double fraction;
  final Color color;
  final bool highlighted;
  final double width;
  final double available;

  @override
  Widget build(BuildContext context) {
    final h = (available * fraction).clamp(2.0, available);
    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        color: highlighted ? color : color.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
