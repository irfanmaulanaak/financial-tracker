import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_motion.dart';
import '../cards/credit_card.dart';

/// Horizontal picker of credit-card tiles for the record-expense flow.
/// Each tile shows the card label, masked last4, a usage progress bar, and
/// remaining credit. Renders a hint text when the household has no cards.
class CardPicker extends StatelessWidget {
  const CardPicker({
    super.key,
    required this.cards,
    required this.selected,
    required this.onSelect,
  });

  final List<CreditCard> cards;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Text(
        'Belum ada kartu. Tambah dari menu Kartu kredit.',
        style: TextStyle(color: FtColors.ink3, fontSize: 12),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(
            child: _CardTile(
              card: cards[i],
              selected: selected == cards[i].id,
              onTap: () => onSelect(cards[i].id),
            ),
          ),
          if (i != cards.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final CreditCard card;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = FtColors.clay;
    final remaining = card.limit - card.used;
    return FtTapScale(
      scale: 0.97,
      haptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.1) : FtColors.surface,
          border: Border.all(
            color: selected ? accent : FtColors.line,
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    card.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '•••• ${card.last4}',
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 10,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: card.limit <= 0
                    ? 0
                    : (card.used / card.limit).clamp(0.0, 1.0),
                minHeight: 2,
                backgroundColor: FtColors.line,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sisa ${Money.format(remaining).replaceFirst('Rp ', 'Rp')}',
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 9.5,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
