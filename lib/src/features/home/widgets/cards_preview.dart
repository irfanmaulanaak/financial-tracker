import 'package:flutter/material.dart';

import '../../../core/cicilan.dart';
import '../../../core/in_app_indicators.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../cards/credit_card.dart';
import 'home_formatters.dart';

class CardsPreview extends StatelessWidget {
  const CardsPreview({super.key, required this.cards, required this.onTap});

  final List<CreditCard> cards;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();
    final used = cards.fold<int>(0, (a, b) => a + b.used);
    final minPay = cards.fold<int>(
      0,
      (a, b) =>
          a + minimumPayment(balance: b.used, minPaymentPct: b.minPaymentPct),
    );

    // Find the card with the soonest due date (rolling to next month if past).
    CreditCard? soonest;
    int? soonestDays;
    for (final c in cards) {
      if (c.used <= 0) continue;
      final d = _nextDueInDays(dueDay: c.dueDay, now: now);
      if (soonestDays == null || d < soonestDays) {
        soonestDays = d;
        soonest = c;
      }
    }

    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Eyebrow('Kartu Kredit · Utang')),
              if (minPay > 0)
                _Chip(
                  text: '${compactMoney(minPay)} min. bayar',
                  color: FtColors.plum,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                compactMoney(used),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(width: 8),
              Text(
                'akumulasi tagihan',
                style: TextStyle(color: FtColors.ink3, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SegmentedLimitBar(cards: cards),
          if (soonest != null || cards.length > 1) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (soonest != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jatuh tempo terdekat',
                          style: TextStyle(
                            color: FtColors.ink3,
                            fontSize: 10,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dueLabel(soonest.dueDay, soonestDays ?? 0,
                              soonest.label),
                          style: TextStyle(
                            color: FtColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Kartu aktif',
                      style: TextStyle(
                        color: FtColors.ink3,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cards.length}',
                      style: TextStyle(
                        color: FtColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static int _nextDueInDays({required int dueDay, required DateTime now}) {
    // Replicates daysUntilDue but always returns a non-null forward-rolling number.
    final d = daysUntilDue(dueDay: dueDay, now: now, warnWithinDays: 365);
    return d ?? 30;
  }

  static String _dueLabel(int dueDay, int days, String cardLabel) {
    final shortName = cardLabel.split(' ').first;
    if (days <= 0) return 'Tgl $dueDay · $shortName (lewat)';
    if (days <= 14) return 'Tgl $dueDay · $shortName ($days hr)';
    return 'Tgl $dueDay · $shortName';
  }
}

/// Stacked-segment bar matching the design's `cards.map(...)` strip — each
/// card occupies width proportional to its limit; fill = used/limit.
class _SegmentedLimitBar extends StatelessWidget {
  const _SegmentedLimitBar({required this.cards});
  final List<CreditCard> cards;

  @override
  Widget build(BuildContext context) {
    final totalLimit = cards.fold<int>(0, (a, b) => a + b.limit);
    if (totalLimit <= 0) {
      return FtProgressBar(value: 0, max: 1, color: FtColors.plum);
    }
    return SizedBox(
      height: 6,
      child: Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(
              flex: (cards[i].limit / totalLimit * 1000).round().clamp(1, 1000),
              child: _SegmentTrack(
                used: cards[i].used,
                limit: cards[i].limit,
              ),
            ),
            if (i != cards.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _SegmentTrack extends StatelessWidget {
  const _SegmentTrack({required this.used, required this.limit});
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final pct = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Container(color: FtColors.line),
          FractionallySizedBox(
            widthFactor: pct,
            child: Container(color: FtColors.plum),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
