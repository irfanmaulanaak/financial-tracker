import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../ui/ft_ui.dart';

/// One actionable line inside [AttentionCard] — a due date or a DSR/budget
/// warning. Not for passive info (streak, daily insight) — those get their
/// own quiet treatment elsewhere, not a slot in this list.
class AttentionItem {
  const AttentionItem({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;
}

/// Single compact card replacing the old stack of separate banner cards —
/// one line per actionable item, a shared chevron affordance. Renders
/// nothing when [items] is empty; there's no "all clear" filler state.
class AttentionCard extends StatelessWidget {
  const AttentionCard({super.key, required this.items});

  final List<AttentionItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Eyebrow('Perlu perhatian'),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _AttentionRow(item: items[i]),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});
  final AttentionItem item;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.99,
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            Icon(item.icon, size: 16, color: item.color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FtColors.ink,
                  fontSize: 12.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: FtColors.ink4),
          ],
        ),
      ),
    );
  }
}
