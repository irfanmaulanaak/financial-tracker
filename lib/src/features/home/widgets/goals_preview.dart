import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
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
    return Column(
      children: [
        FtSectionHeader(
          title: 'Tujuan Finansial',
          actionLabel: '${goals.length} aktif',
          onAction: onTap,
          prominent: true,
        ),
        FtTapScale(
          scale: 0.995,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
            child: Column(
              children: [
                for (var i = 0; i < goals.take(3).length; i++)
                  _GoalPreviewRow(goal: goals[i], showDivider: i > 0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GoalPreviewRow extends StatelessWidget {
  const _GoalPreviewRow({required this.goal, required this.showDivider});

  final Goal goal;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(goal.color);
    return Column(
      children: [
        if (showDivider)
          Divider(height: 1, thickness: 0.5, indent: 31, color: FtColors.line),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Icon(goalIconFor(goal.icon), color: color, size: 19),
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
                            style: TextStyle(
                              color: FtColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(goal.progress * 100).round()}%',
                          style: TextStyle(
                            color: FtColors.ink3,
                            fontSize: 11,
                            fontFeatures: const [FontFeature.tabularFigures()],
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${compactMoney(goal.current)} / ${compactMoney(goal.target)}',
                            style: TextStyle(
                              color: FtColors.ink2,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        if (goal.dueDate != null)
                          Text(
                            Dates.monthYear(goal.dueDate!),
                            style: TextStyle(
                              color: FtColors.ink3,
                              fontSize: 11,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
