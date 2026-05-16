import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../goals/goal.dart';
import 'home_formatters.dart';

class GoalsPreview extends StatelessWidget {
  const GoalsPreview({super.key, required this.goals, required this.onTap});

  final List<Goal> goals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              children: [
                const Expanded(child: Eyebrow('Tujuan Finansial')),
                Text(
                  '${goals.length} aktif',
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          for (final g in goals.take(3)) _GoalPreviewRow(goal: g),
        ],
      ),
    );
  }
}

class _GoalPreviewRow extends StatelessWidget {
  const _GoalPreviewRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(goal.color);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: FtColors.line, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(goalIconFor(goal.icon), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FtColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${(goal.progress * 100).round()}%',
                      style: const TextStyle(
                        color: FtColors.ink3,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                FtProgressBar(
                  value: goal.current,
                  max: goal.target,
                  color: color,
                  height: 3,
                ),
                const SizedBox(height: 6),
                Text(
                  '${compactMoney(goal.current)} / ${compactMoney(goal.target)}',
                  style: const TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
