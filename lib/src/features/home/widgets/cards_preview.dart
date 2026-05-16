import 'package:flutter/material.dart';

import '../../../core/cicilan.dart';
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
    final used = cards.fold<int>(0, (a, b) => a + b.used);
    final limit = cards.fold<int>(0, (a, b) => a + b.limit);
    final minPay = cards.fold<int>(
      0,
      (a, b) =>
          a + minimumPayment(balance: b.used, minPaymentPct: b.minPaymentPct),
    );
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Kartu Kredit · Utang'),
          const SizedBox(height: 8),
          Text(
            compactMoney(used),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'akumulasi tagihan',
            style: TextStyle(color: FtColors.ink3, fontSize: 12),
          ),
          const SizedBox(height: 12),
          FtProgressBar(
            value: used,
            max: limit <= 0 ? 1 : limit,
            color: FtColors.plum,
          ),
          const SizedBox(height: 14),
          FtStatGrid(
            items: [
              FtStatItem(label: 'Limit total', value: compactMoney(limit)),
              FtStatItem(label: 'Min. bayar', value: compactMoney(minPay)),
              FtStatItem(label: 'Kartu aktif', value: '${cards.length}'),
            ],
          ),
        ],
      ),
    );
  }
}
