import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters.dart';
import '../../../core/hide_assets_provider.dart';
import '../../../core/net_worth.dart';
import '../../../theme.dart';
import '../../../ui/ft_animated_number.dart';
import '../../../ui/ft_sparkline.dart';
import '../../../ui/ft_ui.dart';
import 'home_formatters.dart';

/// ---------------------------------------------------------------------------
/// Slide 1 — Total Aset
/// ---------------------------------------------------------------------------
class AsetSlide extends ConsumerStatefulWidget {
  const AsetSlide({
    super.key,
    required this.nw,
    required this.trend,
    required this.trendDates,
    required this.cycleNet,
  });

  final NetWorth nw;
  final List<double> trend;
  final List<DateTime> trendDates;
  final int cycleNet;

  @override
  ConsumerState<AsetSlide> createState() => _AsetSlideState();
}

class _AsetSlideState extends ConsumerState<AsetSlide> {
  /// Index into [AsetSlide.trend] currently under the pointer, if any.
  int? _scrubIdx;

  @override
  Widget build(BuildContext context) {
    final nw = widget.nw;
    final trend = widget.trend;
    final cycleNet = widget.cycleNet;
    final hidden = ref.watch(hideAssetsProvider);
    final showDelta = !hidden && cycleNet != 0 && nw.total > 0;
    final positive = cycleNet >= 0;
    // Trend direction (first vs. last point), not this cycle's cash flow —
    // the chart draws net worth over time, so its color should track that,
    // not `positive` (a one-cycle spent-vs-earned sign that can disagree
    // with a net worth line that's actually trending up).
    final trendPositive = trend.length < 2 || trend.last >= trend.first;
    final canScrub = !hidden && widget.trendDates.length == trend.length;
    final scrub = _scrubIdx != null && canScrub && _scrubIdx! < trend.length
        ? (
            date: widget.trendDates[_scrubIdx!],
            total: trend[_scrubIdx!].round(),
          )
        : null;
    return FtCard(
      // Follows the "Warna" accent, not a (palette-fixed) category color —
      // this card isn't about one category.
      backgroundColor: FtColors.tileFor(FtColors.clay),
      heroTag: 'ft-aset-hero',
      onTap: () => context.push('/accounts'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              // Net of card debt — distinct from the gross "Total Aset" on
              // the Aset screen.
              Expanded(child: Eyebrow('Kekayaan Bersih')),
              HideAssetsEye(),
            ],
          ),
          const SizedBox(height: 6),
          hidden
              ? Text(
                  maskMoney(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 32,
                        height: 1,
                        letterSpacing: -1,
                        fontWeight: FontWeight.w500,
                        color: FtColors.ink,
                      ),
                )
              : FtAnimatedNumber(
                  value: nw.total,
                  formatter: compactMoney,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 32,
                        height: 1,
                        letterSpacing: -1,
                        fontWeight: FontWeight.w500,
                        color: FtColors.ink,
                      ),
                ),
          const SizedBox(height: 8),
          // Fixed-height slot so scrubbing the sparkline swaps the
          // pill for the day readout without layout jitter.
          SizedBox(
            height: 22,
            child: Align(
              alignment: Alignment.centerLeft,
              child: scrub != null
                  ? Text(
                      '${Dates.dayMonth(scrub.date)} · '
                      '${Money.format(scrub.total)}',
                      style: TextStyle(
                        color: FtColors.ink2,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    )
                  : showDelta
                      ? _DeltaPill(
                          positive: positive,
                          amount: cycleNet.abs(),
                        )
                      : Text(
                          'Tunai, tabungan, dan investasi, dikurangi utang',
                          style: TextStyle(
                            color: FtColors.ink3,
                            fontSize: 11,
                          ),
                        ),
            ),
          ),
          if (trend.length >= 2) ...[
            const SizedBox(height: 10),
            // Full width, otherwise the SizedBox collapses to 0 and
            // the trend renders as a vertical stub.
            FtSparkline(
              data: trend,
              width: double.infinity,
              height: 26,
              color: trendPositive ? FtColors.moss : FtColors.danger,
              onHoverPoint:
                  canScrub ? (i) => setState(() => _scrubIdx = i) : null,
            ),
            if (widget.trendDates.length == trend.length) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    Dates.dayMonth(widget.trendDates.first),
                    style: TextStyle(color: FtColors.ink4, fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    Dates.dayMonth(widget.trendDates.last),
                    style: TextStyle(color: FtColors.ink4, fontSize: 10),
                  ),
                ],
              ),
            ],
          ],
          const SizedBox(height: 12),
          Container(height: 0.5, color: FtColors.line),
          const SizedBox(height: 10),
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
