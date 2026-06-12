import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/streak.dart';
import '../../../theme.dart';
import 'home_formatters.dart';

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
      actionLabel: 'Lihat',
      onAction: () => context.push('/cards'),
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
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String text;

  /// Aksi kecil di kanan banner ("peringatan selalu berpasangan dengan
  /// langkah berikutnya"). Keduanya null = banner pasif.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final band = Container(
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
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            Text(
              actionLabel!,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: color,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 16),
          ],
        ],
      ),
    );
    if (onAction == null) return band;
    return GestureDetector(onTap: onAction, child: band);
  }
}
