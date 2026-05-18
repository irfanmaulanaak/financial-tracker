import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../credit_card.dart';

/// Hero card on the card-detail screen. Pure display widget.
class CardDetailHeader extends StatelessWidget {
  const CardDetailHeader({
    super.key,
    required this.card,
    required this.available,
  });

  final CreditCard card;
  final int available;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(card.accent);
    final pct = card.limit == 0
        ? 0.0
        : (card.used / card.limit).clamp(0.0, 1.0);
    return FtCard(
      backgroundColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              if (card.last4.isNotEmpty)
                Text(
                  '•••• ${card.last4}',
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Terpakai',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            Money.format(card.used),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tersedia: ${Money.format(available)} dari ${Money.format(card.limit)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jatuh tempo: tgl ${card.dueDay}  •  APR: ${(card.apr * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class CardInstallmentTile extends StatelessWidget {
  const CardInstallmentTile({
    super.key,
    required this.inst,
    required this.onPaidOne,
    this.onEdit,
    this.onDelete,
  });

  final Installment inst;
  final VoidCallback onPaidOne;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final pct = inst.monthsPaid / inst.monthsTotal;
    return FtCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    inst.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${inst.monthsPaid}/${inst.monthsTotal} bln',
                  style: const TextStyle(fontSize: 12),
                ),
                if (onEdit != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Edit cicilan',
                    onPressed: onEdit,
                    icon: Icon(Icons.edit_outlined,
                        size: 16, color: FtColors.ink2),
                  ),
                if (onDelete != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Hapus cicilan',
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline,
                        size: 16, color: FtColors.danger),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: FtProgressBar(value: pct, max: 1, color: FtColors.sky),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cicilan: ${Money.format(inst.monthly)} / bln  •  Sisa: ${Money.format(inst.remainingAmount)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (!inst.isComplete)
                  TextButton(
                    onPressed: onPaidOne,
                    child: const Text('Bayar bulan ini'),
                  )
                else
                  const Chip(
                    label: Text('Lunas'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
