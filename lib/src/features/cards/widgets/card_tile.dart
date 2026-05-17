import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_motion.dart';
import '../../../ui/ft_ui.dart';
import '../credit_card.dart';
import '../pay_card_sheet.dart';
import 'installment_list.dart';

/// Per-card tile shown on the Cards screen — gradient card visual with
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
              color: color,
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, FtColors.plum],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.label.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  card.last4.isNotEmpty ? '•••• ${card.last4}' : '',
                  style: const TextStyle(
                    color: Colors.white,
                    letterSpacing: 2,
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
                            ?.copyWith(color: Colors.white, fontSize: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FtProgressBar(
                  value: pct,
                  max: 1,
                  color: Colors.white,
                  trackColor: Colors.white24,
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
