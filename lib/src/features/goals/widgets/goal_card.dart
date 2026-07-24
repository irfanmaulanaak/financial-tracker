import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../goal.dart';
import 'goal_funding_sheet.dart';

/// Tap-friendly goal row used by `GoalsScreen`. Icon badge + label + percent
/// + tone progress bar + amounts/due/monthly + an "off-track" warning when the
/// remaining-per-month implies it won't make the deadline.
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.ownerLabel,
    required this.onContribute,
    required this.onDelete,
    this.fundingAsset,
  });

  final Goal goal;
  final String ownerLabel;
  final VoidCallback onContribute;
  final VoidCallback onDelete;

  /// Non-null untuk goal yang terhubung ke aset: tombol setor diganti
  /// label sumber dananya.
  final GoalFundingAsset? fundingAsset;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(goal.color);
    final months = monthsToGoal(
      target: goal.target,
      current: goal.current,
      monthlyContrib: goal.monthlyContrib,
    );
    final pct = (goal.progress * 100).round();
    final remaining = goal.remaining;
    final onTrack = pct >= 50 || (months ?? 9999) <= 6;
    final urgentMonthly = remaining > 0
        ? (remaining / 6).ceil()
        : 0;

    // No onLongPress here: holding the card is the reorder gesture
    // (ReorderableDelayedDragStartListener in GoalsScreen). Delete lives in
    // the ⋯ menu instead.
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      onTap: () => context.push('/goals/${goal.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: color.withValues(alpha: 0.32), width: 0.5),
                ),
                child: Icon(goalIconFor(goal.icon), color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            goal.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 16),
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: TextStyle(
                            color: FtColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FtProgressBar(
                      value: goal.current,
                      max: goal.target == 0 ? 1 : goal.target,
                      color: color,
                      height: 4,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${compactMoney(goal.current)} / ${compactMoney(goal.target)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: FtColors.ink2,
                              fontSize: 11,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _trailingLabel(goal),
                          style: TextStyle(
                              color: FtColors.ink3, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 30,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  tooltip: 'Opsi tujuan',
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: FtColors.ink3,
                  ),
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ),
            ],
          ),
          if (!onTrack && remaining > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: FtColors.ochre.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: FtColors.ochre.withValues(alpha: 0.28),
                    width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 12, color: FtColors.ochre),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Naikkan setoran ke ${compactMoney(urgentMonthly)}/bln agar tercapai tepat waktu.',
                      style: TextStyle(
                        color: FtColors.ink2,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (fundingAsset != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: FtColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: FtColors.line, width: 0.5),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link,
                    size: 12,
                    color: fundingAsset!.missing
                        ? FtColors.danger
                        : FtColors.ink3,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      fundingAsset!.missing
                          ? 'Aset tidak ditemukan'
                          : 'Dari ${fundingAsset!.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fundingAsset!.missing
                            ? FtColors.danger
                            : FtColors.ink2,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FtTapScale(
                    scale: 0.97,
                    onTap: goal.isComplete ? null : onContribute,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: goal.isComplete
                            ? FtColors.line
                            : FtColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: FtColors.line, width: 0.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        goal.isComplete ? 'Tercapai' : '+ Setor',
                        style: TextStyle(
                          color: goal.isComplete ? FtColors.ink3 : FtColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _trailingLabel(Goal g) {
    if (g.isComplete) return 'Tercapai';
    final months = monthsToGoal(
      target: g.target,
      current: g.current,
      monthlyContrib: g.monthlyContrib,
    );
    if (g.monthlyContrib > 0) {
      return '${compactMoney(g.monthlyContrib)}/bln · ${months ?? '?'} bln';
    }
    return 'Sisa ${compactMoney(g.remaining)}';
  }
}
