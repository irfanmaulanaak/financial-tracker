import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../goal.dart';

class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.goal,
    required this.ownerLabel,
    required this.onContribute,
    required this.onDelete,
  });
  final Goal goal;
  final String ownerLabel;
  final VoidCallback onContribute;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(goal.color);
    final months = monthsToGoal(
      target: goal.target,
      current: goal.current,
      monthlyContrib: goal.monthlyContrib,
    );
    return Card(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(_iconFor(goal.icon), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$ownerLabel • ${goalScopeLabel(goal.scope)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${Money.format(goal.current)} / ${Money.format(goal.target)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (goal.isComplete)
                  const Chip(
                    label: Text('Tercapai'),
                    visualDensity: VisualDensity.compact,
                  )
                else if (months != null)
                  Text(
                    '±$months bln lagi',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  )
                else
                  Text(
                    'Sisa ${Money.format(goal.remaining)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: goal.isComplete ? null : onContribute,
              child: const Text('Tambah dana'),
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

IconData _iconFor(String name) => switch (name) {
      'savings' => Icons.savings,
      'flight' => Icons.flight_takeoff,
      'home' => Icons.home,
      'school' => Icons.school,
      'directions_car' => Icons.directions_car,
      'celebration' => Icons.celebration,
      _ => Icons.flag,
    };
