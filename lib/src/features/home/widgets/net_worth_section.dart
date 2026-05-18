import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hide_assets_provider.dart';
import '../../../core/net_worth.dart';
import '../../../theme.dart';
import '../../../ui/ft_donut.dart';
import '../../../ui/ft_sparkline.dart';
import '../../../ui/ft_ui.dart';
import 'home_formatters.dart';

/// Combined asset hero card — replaces the older AssetHero + AssetBreakdown
/// pair. Matches the dense layout in `claude-design/design/screens-home.jsx`
/// (total + mini donut + sparkline + 3-col breakdown).
class AssetHeroCard extends ConsumerWidget {
  const AssetHeroCard({
    super.key,
    required this.nw,
    required this.onTap,
    this.cycleNet,
    this.trend = const [],
  });

  final NetWorth nw;
  final VoidCallback onTap;

  /// Optional cycle net (income − spend); renders a small +/- delta pill.
  final int? cycleNet;

  /// Optional 7..14-point trend series for the asset sparkline. When empty,
  /// the sparkline is skipped.
  final List<double> trend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideAssetsProvider);
    final showDelta =
        !hidden && cycleNet != null && cycleNet != 0 && nw.total > 0;
    final positive = (cycleNet ?? 0) >= 0;
    final segments = <FtDonutSegment>[
      if (nw.cash > 0)
        FtDonutSegment(value: nw.cash.toDouble(), color: FtColors.sky),
      if (nw.savings > 0)
        FtDonutSegment(value: nw.savings.toDouble(), color: FtColors.moss),
      if (nw.investments > 0)
        FtDonutSegment(value: nw.investments.toDouble(), color: FtColors.clay),
    ];

    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Eyebrow('Total Aset'),
              const Spacer(),
              const HideAssetsEye(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FtFadeUp(
                      duration: const Duration(milliseconds: 420),
                      distance: 6,
                      child: Text(
                        hidden ? maskMoney() : compactMoney(nw.total),
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                              fontSize: 36,
                              height: 1,
                              letterSpacing: -1,
                              fontWeight: FontWeight.w500,
                              color: FtColors.ink,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (showDelta)
                      _DeltaPill(positive: positive, amount: cycleNet!.abs())
                    else
                      Text(
                        'Total tunai + tabungan + investasi',
                        style: TextStyle(color: FtColors.ink3, fontSize: 11),
                      ),
                    if (trend.length >= 2) ...[
                      const SizedBox(height: 10),
                      FtSparkline(
                        data: trend,
                        height: 24,
                        color: positive ? FtColors.moss : FtColors.danger,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (segments.isNotEmpty)
                FtDonut(segments: segments, size: 78, thickness: 10),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 0.5, color: FtColors.line),
          const SizedBox(height: 12),
          Row(
            children: [
              _BreakdownStat(
                label: 'Tunai',
                value: nw.cash,
                color: FtColors.sky,
                hidden: hidden,
              ),
              const SizedBox(width: 8),
              _BreakdownStat(
                label: 'Tabungan',
                value: nw.savings,
                color: FtColors.moss,
                hidden: hidden,
              ),
              const SizedBox(width: 8),
              _BreakdownStat(
                label: 'Investasi',
                value: nw.investments,
                color: FtColors.clay,
                hidden: hidden,
              ),
              if (nw.debt > 0) ...[
                const SizedBox(width: 8),
                _BreakdownStat(
                  label: 'Utang',
                  value: -nw.debt,
                  color: FtColors.plum,
                  hidden: hidden,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownStat extends StatelessWidget {
  const _BreakdownStat({
    required this.label,
    required this.value,
    required this.color,
    this.hidden = false,
  });

  final String label;
  final int value;
  final Color color;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink3,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            hidden ? maskMoney() : compactMoney(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: FtColors.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.positive, required this.amount});
  final bool positive;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final color = positive ? FtColors.moss : FtColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            '${positive ? '+' : '−'}${compactMoney(amount)} siklus ini',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

