import 'package:flutter/material.dart';

import '../../core/cicilan.dart';
import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_motion.dart';

/// Four-option grid (Lunas / 3× / 6× / 12×) that selects an installment plan
/// for the record-expense credit-card path. The 12× option uses the card's
/// APR; shorter terms are interest-free.
class InstallmentPlans extends StatelessWidget {
  const InstallmentPlans({
    super.key,
    required this.cicilan,
    required this.months,
    required this.apr,
    required this.onSelect,
  });

  final bool cicilan;
  final int months;
  final double apr;
  final void Function(int months, double apr) onSelect;

  @override
  Widget build(BuildContext context) {
    final plans = [
      (1, 0.0, 'Lunas'),
      (3, 0.0, '3×'),
      (6, 0.0, '6×'),
      (12, apr, '12×'),
    ];
    return Row(
      children: [
        for (var i = 0; i < plans.length; i++) ...[
          Expanded(
            child: _planChip(
              label: plans[i].$3,
              apr: plans[i].$2,
              selected: cicilan
                  ? months == plans[i].$1
                  : plans[i].$1 == 1,
              onTap: () => onSelect(plans[i].$1, plans[i].$2),
            ),
          ),
          if (i != plans.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _planChip({
    required String label,
    required double apr,
    required bool selected,
    required VoidCallback onTap,
  }) {
    // "penuh" = single full payment; "0%" = interest-free installment;
    // "{apr}% pa" = installment that accrues at the card's APR.
    final caption = label == 'Lunas'
        ? 'penuh'
        : apr == 0
            ? '0%'
            : '${(apr * 100).toStringAsFixed(0)}% pa';
    return FtTapScale(
      scale: 0.95,
      haptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? FtColors.ink : FtColors.surface,
          border: Border.all(
            color: selected ? FtColors.ink : FtColors.line,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Newsreader',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? FtColors.bg : FtColors.ink2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              caption,
              style: TextStyle(
                color: selected ? FtColors.bg : FtColors.ink3,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Monthly / total / interest breakdown rendered below the plan picker when
/// an installment plan is active. Numbers come from `computeCicilan`.
class InstallmentPreview extends StatelessWidget {
  const InstallmentPreview({
    super.key,
    required this.amount,
    required this.months,
    required this.apr,
  });

  final int amount;
  final int months;
  final double apr;

  @override
  Widget build(BuildContext context) {
    final plan = computeCicilan(principal: amount, months: months, apr: apr);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        border: Border.all(color: FtColors.line, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cicilan per bulan',
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ),
              Text.rich(
                TextSpan(
                  text: Money.format(plan.monthly),
                  style: TextStyle(
                    fontFamily: 'Newsreader',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: FtColors.ink,
                  ),
                  children: [
                    TextSpan(
                      text: ' × $months bln',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: FtColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total bayar',
                  style: TextStyle(color: FtColors.ink3, fontSize: 10),
                ),
              ),
              Text(
                Money.format(plan.total),
                style: TextStyle(
                  fontSize: 10,
                  color: FtColors.ink3,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (plan.totalInterest > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bunga (${(apr * 100).toStringAsFixed(1)}% pa)',
                      style: TextStyle(color: FtColors.ink3, fontSize: 10),
                    ),
                  ),
                  Text(
                    '+${Money.format(plan.totalInterest)}',
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 10,
                      fontFeatures: [FontFeature.tabularFigures()],
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
