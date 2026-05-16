import 'package:flutter/material.dart';

import '../../../core/health_score.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import 'home_formatters.dart';

class HealthSnapshot extends StatelessWidget {
  const HealthSnapshot({super.key, required this.score, required this.onTap});

  final HealthScore score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = healthColor(score.score);
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score.score / 100,
                  strokeWidth: 6,
                  color: color,
                  backgroundColor: FtColors.line,
                ),
                Text(
                  '${score.score}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Kesehatan Finansial'),
                const SizedBox(height: 4),
                Text(
                  score.verdict,
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
                  style: const TextStyle(color: FtColors.ink2, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: FtColors.ink4),
        ],
      ),
    );
  }

  static String _summary(HealthScore score) {
    final available = score.factors.where((f) => f.contribution != null).toList()
      ..sort((a, b) => (a.contribution ?? 0).compareTo(b.contribution ?? 0));
    if (available.isEmpty) return 'Data belum cukup untuk membaca pola.';
    return '${available.first.label} paling perlu perhatian.';
  }
}
