import 'package:flutter/material.dart';

import '../../../core/net_worth.dart';
import '../../../theme.dart';
import '../../../ui/ft_motion.dart';
import '../../../ui/ft_ui.dart';
import 'home_formatters.dart';

class AssetHero extends StatelessWidget {
  const AssetHero({
    super.key,
    required this.nw,
    required this.onTap,
    this.cycleNet,
  });

  final NetWorth nw;
  final VoidCallback onTap;

  /// This cycle's net (income − spend). When non-null and assets > 0,
  /// renders a green/red pill below the hero number.
  final int? cycleNet;

  @override
  Widget build(BuildContext context) {
    final showDelta = cycleNet != null && cycleNet != 0 && nw.total > 0;
    final positive = (cycleNet ?? 0) >= 0;
    final pctOfTotal = showDelta && nw.total > 0
        ? ((cycleNet!.abs() / nw.total) * 100).toStringAsFixed(1)
        : null;
    return FtTapScale(
      scale: 0.985,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Total Aset'),
            const SizedBox(height: 10),
            FtFadeUp(
              duration: const Duration(milliseconds: 420),
              distance: 6,
              child: Text.rich(
                TextSpan(
                  text: moneyNoSymbol(nw.total),
                  children: [
                    TextSpan(
                      text: ' IDR',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: FtColors.ink3,
                        letterSpacing: 0,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 46,
                      height: 1,
                      letterSpacing: -1.5,
                      fontWeight: FontWeight.w500,
                      color: FtColors.ink,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            if (showDelta)
              Row(
                children: [
                  _DeltaPill(
                      positive: positive,
                      amount: cycleNet!.abs(),
                      pct: pctOfTotal),
                  const SizedBox(width: 10),
                  Text(
                    'siklus ini',
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Tunai + tabungan + investasi · dikurangi utang',
                style: TextStyle(
                  color: FtColors.ink3,
                  fontSize: 11,
                  letterSpacing: 0.1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({
    required this.positive,
    required this.amount,
    required this.pct,
  });
  final bool positive;
  final int amount;
  final String? pct;

  @override
  Widget build(BuildContext context) {
    final color = positive ? FtColors.moss : FtColors.danger;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '${positive ? '+' : '−'}${compactMoney(amount)}${pct != null ? ' · ${positive ? '+' : '−'}$pct%' : ''}',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class AssetBreakdown extends StatelessWidget {
  const AssetBreakdown({super.key, required this.nw, required this.onTap});

  final NetWorth nw;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        children: [
          _BreakdownRow('Tunai', 'rekening siap pakai', nw.cash, FtColors.sky),
          const Divider(),
          _BreakdownRow(
            'Tabungan',
            'dana tersimpan',
            nw.savings,
            FtColors.moss,
          ),
          const Divider(),
          _BreakdownRow(
            'Investasi',
            'reksadana, saham, emas',
            nw.investments,
            FtColors.clay,
          ),
          if (nw.debt > 0) ...[
            const Divider(),
            _BreakdownRow(
              'Utang kartu',
              'mengurangi aset',
              -nw.debt,
              FtColors.plum,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow(this.label, this.hint, this.value, this.color);

  final String label;
  final String hint;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                ),
              ],
            ),
          ),
          Text(
            compactMoney(value),
            style: TextStyle(
              color: color,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
