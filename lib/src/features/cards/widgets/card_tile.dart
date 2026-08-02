import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../credit_card.dart';
import '../pay_card_sheet.dart';
import 'installment_list.dart';

/// Per-card tile shown on the Cards screen — tonal card visual with
/// label/last4, used amount, usage bar, owner/limit/due grid, active
/// installments list, and pay actions.
class CardTile extends StatelessWidget {
  const CardTile({
    super.key,
    required this.card,
    required this.hid,
    required this.ownerName,
    required this.onTap,
  });

  final CreditCard card;
  final String hid;
  final String ownerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(card.accent);
    final cardSurface = Color.lerp(color, FtColors.surface, 0.68)!;
    final pct =
        card.limit == 0 ? 0.0 : (card.used / card.limit).clamp(0.0, 1.0);
    return FtCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(minHeight: 132),
            decoration: BoxDecoration(
              color: cardSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: FtColors.ink2,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.account_balance,
                      color: FtColors.ink,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card.last4.isNotEmpty ? '•••• ${card.last4}' : '',
                  style: TextStyle(
                    color: FtColors.ink,
                    letterSpacing: 2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        Money.format(card.used),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: FtColors.ink, fontSize: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FtProgressBar(
                  value: pct,
                  max: 1,
                  color: ftProgressColor(
                    card.used,
                    card.limit,
                    dangerWhenOver: true,
                  ),
                  trackColor: FtColors.ink.withValues(alpha: 0.14),
                  height: 3,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: FtStatGrid(
              items: [
                FtStatItem(label: 'Pemilik', value: ownerName),
                FtStatItem(label: 'Limit', value: Money.format(card.limit)),
                FtStatItem(
                    label: 'Tagihan keluar', value: 'Tgl ${card.billingDay}'),
                FtStatItem(label: 'Jatuh tempo', value: 'Tgl ${card.dueDay}'),
              ],
            ),
          ),
          CardInstallmentsInline(hid: hid, cardId: card.id),
          _CardActions(hid: hid, card: card),
        ],
      ),
    );
  }
}

class _CardActions extends ConsumerWidget {
  const _CardActions({required this.hid, required this.card});

  final String hid;
  final CreditCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (card.used <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: FtTapScale(
        scale: 0.97,
        onTap: () =>
            PayCardSheet.show(context: context, hid: hid, card: card),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: FtColors.ink,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            'Bayar tagihan',
            style: TextStyle(
              color: FtColors.bg,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
