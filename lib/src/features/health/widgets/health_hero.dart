import 'package:flutter/material.dart';

import '../../../core/health_score.dart';
import '../../../theme.dart';
import '../../../ui/ft_traffic_light.dart';
import '../../../ui/ft_ui.dart';

/// Hero card on the health detector screen — vertical traffic light + score
/// + verdict label + tinted summary box. Mirrors the top of `HealthScreen`
/// in `claude-design/screens-rest.jsx`.
class HealthHero extends StatelessWidget {
  const HealthHero({super.key, required this.score});
  final HealthScore score;

  // Tiers align with `verdictFor` (>=65 sehat, >=50 cukup, <50 below).
  Color _colorFor(int s) {
    if (s >= 65) return FtColors.healthOk;
    if (s >= 50) return FtColors.healthWarn;
    return FtColors.healthBad;
  }

  FtHealthState _stateFor(int s) {
    if (s >= 65) return FtHealthState.good;
    if (s >= 50) return FtHealthState.caution;
    return FtHealthState.risk;
  }

  String _summary() {
    final weakest = score.weakestFactor;
    if (weakest == null) return 'Data belum cukup untuk membaca pola.';
    return '${weakest.label} paling perlu perhatian.';
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(score.score);
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FtColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: FtColors.line, width: 0.5),
                ),
                child: FtTrafficLight(
                  state: _stateFor(score.score),
                  vertical: true,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Status Siklus Ini'),
                    const SizedBox(height: 4),
                    Text(
                      score.verdict,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: color,
                            fontSize: 22,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${score.score}',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(fontSize: 38, height: 1),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '/ 100',
                          style: TextStyle(color: FtColors.ink3, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: color.withValues(alpha: 0.28), width: 0.5),
            ),
            child: Text(
              _summary(),
              style: TextStyle(
                color: FtColors.ink2,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
