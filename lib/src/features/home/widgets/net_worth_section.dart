import 'package:flutter/material.dart';

import '../../../core/net_worth.dart';
import '../../../theme.dart';
import '../../../ui/ft_motion.dart';
import '../../../ui/ft_ui.dart';
import 'home_formatters.dart';

class AssetHero extends StatelessWidget {
  const AssetHero({super.key, required this.nw, required this.onTap});

  final NetWorth nw;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.985,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
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
                  children: const [
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
            const Text(
              'Tunai + tabungan dikurangi utang kartu',
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
            'Utang kartu',
            'mengurangi aset',
            -nw.debt,
            FtColors.plum,
          ),
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
                  style: const TextStyle(
                    color: FtColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
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
