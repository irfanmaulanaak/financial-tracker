import 'package:flutter/material.dart';

import '../../../core/allocation_recommendation.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';

/// "Langkah Rebalancing" section under the allocation card. Renders a header
/// pill with the move count + a card with one row per move (`from → to` +
/// reason + amount). Returns a single info card when no moves are needed.
class RebalanceMoves extends StatelessWidget {
  const RebalanceMoves({super.key, required this.rec});
  final AllocationRecommendation rec;

  @override
  Widget build(BuildContext context) {
    if (rec.moves.isEmpty) {
      return FtCard(
        child: Row(
          children: [
            Icon(Icons.check_circle_outline,
                size: 16, color: FtColors.healthOk),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                rec.inBalance
                    ? 'Alokasi sudah dekat dengan profil moderat. Tidak perlu rebalance.'
                    : 'Belum ada langkah rebalancing yang signifikan.',
                style: TextStyle(
                  color: FtColors.ink2,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Eyebrow('Langkah Rebalancing')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: FtColors.clay.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: FtColors.clay.withValues(alpha: 0.3),
                    width: 0.5),
              ),
              child: Text(
                '${rec.moves.length} aksi',
                style: TextStyle(
                  color: FtColors.clay,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FtCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rec.moves.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _MoveRow(move: rec.moves[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MoveRow extends StatelessWidget {
  const _MoveRow({required this.move});
  final AllocationMove move;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              _Pill(label: '− ${move.from}', color: FtColors.danger),
              Icon(Icons.arrow_forward_rounded,
                  size: 13, color: FtColors.ink4),
              _Pill(label: '+ ${move.to}', color: FtColors.moss),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  move.reason,
                  style: TextStyle(
                    color: FtColors.ink2,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                compactMoney(move.amount),
                style: TextStyle(
                  color: FtColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border:
            Border.all(color: color.withValues(alpha: 0.32), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
