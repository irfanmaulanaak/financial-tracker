import 'package:flutter/material.dart';

import '../../../core/in_app_indicators.dart';
import '../../../core/streak.dart';
import '../../../theme.dart';
import 'home_formatters.dart';

class BudgetBanner extends StatelessWidget {
  const BudgetBanner({super.key, required this.status});

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final exceeded = status == BudgetStatus.exceeded;
    final color = exceeded ? FtColors.danger : FtColors.ochre;
    final msg = exceeded
        ? 'Pengeluaran sudah melampaui pendapatan siklus ini.'
        : 'Sudah 80% dari pendapatan siklus ini.';
    return AlertBand(icon: Icons.warning_amber_rounded, color: color, text: msg);
  }
}

class DueBanner extends StatelessWidget {
  const DueBanner({
    super.key,
    required this.cardLabel,
    required this.daysUntil,
    required this.used,
  });

  final String cardLabel;
  final int daysUntil;
  final int used;

  @override
  Widget build(BuildContext context) {
    final urgent = daysUntil <= 0;
    final text = urgent
        ? '$cardLabel jatuh tempo hari ini · ${compactMoney(used)}'
        : '$cardLabel jatuh tempo $daysUntil hari lagi · ${compactMoney(used)}';
    return AlertBand(
      icon: Icons.credit_card_rounded,
      color: urgent ? FtColors.danger : FtColors.sage,
      text: text,
    );
  }
}

/// Positive-only habit nudge: shown from 2 consecutive recorded days,
/// hidden entirely otherwise (no guilt-tripping zero states).
class StreakBanner extends StatelessWidget {
  const StreakBanner({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return AlertBand(
      icon: Icons.local_fire_department_rounded,
      color: FtColors.clay,
      text: streakLabel(streak),
    );
  }
}

class AlertBand extends StatelessWidget {
  const AlertBand({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.26), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
