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
      color: urgent ? FtColors.danger : FtColors.ochre,
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
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: FtColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FtColors.tileFor(color),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(width: 8),
            Text(
              actionLabel!,
              style: TextStyle(
                color: FtColors.clay,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: FtColors.clay, size: 18),
          ],
        ],
      ),
    );
    if (onAction == null) return band;
    return GestureDetector(onTap: onAction, child: band);
  }
}
