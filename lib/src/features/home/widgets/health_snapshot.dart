import 'package:flutter/material.dart';

import '../../../core/health_score.dart';
import '../../../theme.dart';
import '../../../ui/ft_ring.dart';
import '../../../ui/ft_traffic_light.dart';
import '../../../ui/ft_ui.dart';

class HealthSnapshot extends StatelessWidget {
  const HealthSnapshot({
    super.key,
    required this.score,
    required this.onTap,
    this.compact = false,
  });

  final HealthScore score;
  final VoidCallback onTap;

  /// When true, renders the tighter side-by-side variant suitable for the
  /// home page's spend/health row.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = _stateFor(score.score);
    final color = _colorFor(state);
    final label = score.verdict;

    if (compact) {
      return FtCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: Eyebrow('Kesehatan')),
                FtTrafficLight(state: state, vertical: true, size: 7),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${score.score}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 32,
                    height: 1,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: FtColors.ink2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '/ 100 · siklus ini',
              style: TextStyle(color: FtColors.ink3, fontSize: 10.5),
            ),
          ],
        ),
      );
    }

    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      onTap: onTap,
      child: Row(
        children: [
          FtRing(
            value: score.score.toDouble(),
            max: 100,
            size: 64,
            thickness: 6,
            color: color,
            child: Text(
              '${score.score}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Eyebrow('Kesehatan Finansial')),
                    FtTrafficLight(state: state, size: 8),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  _summary(score),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static FtHealthState _stateFor(int score) {
    if (score >= 80) return FtHealthState.good;
    if (score >= 50) return FtHealthState.caution;
    return FtHealthState.risk;
  }

  static Color _colorFor(FtHealthState s) => switch (s) {
        FtHealthState.good => FtColors.healthOk,
        FtHealthState.caution => FtColors.healthWarn,
        FtHealthState.risk => FtColors.healthBad,
      };

  static String _summary(HealthScore score) {
    final available =
        score.factors.where((f) => f.contribution != null).toList()
          ..sort((a, b) => (a.contribution ?? 0).compareTo(b.contribution ?? 0));
    if (available.isEmpty) return 'Data belum cukup untuk membaca pola.';
    return '${available.first.label} paling perlu perhatian.';
  }
}
