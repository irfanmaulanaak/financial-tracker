import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/allocation_recommendation.dart';
import '../../../theme.dart';
import '../../../ui/ft_donut.dart';
import '../../../ui/ft_haptics.dart';
import '../../../ui/ft_refresh.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household.dart';
import '../../household/household_providers.dart' show currentHouseholdProvider;
import '../../investments/investment.dart';
import 'rebalance_moves.dart';

/// Allocation tab body: market context card → current/target donut +
/// breakdown + summary → rebalancing moves list. Mirrors `AllocationView`
/// in `claude-design/screens-assets.jsx`.
class AlokasiTab extends ConsumerStatefulWidget {
  const AlokasiTab({
    super.key,
    required this.household,
    required this.investments,
  });
  final Household household;
  final List<Investment> investments;

  @override
  ConsumerState<AlokasiTab> createState() => _AlokasiTabState();
}

class _AlokasiTabState extends ConsumerState<AlokasiTab> {
  /// `false` = Sekarang (actual), `true` = Direkomendasikan (target).
  bool _showTarget = true;

  @override
  Widget build(BuildContext context) {
    final cash = widget.household.cashAccounts
        .fold<int>(0, (a, b) => a + b.value);
    final savings = widget.household.savingsAccounts
        .fold<int>(0, (a, b) => a + b.value);
    final rec = computeAllocation(
      cashTotal: cash,
      savingsTotal: savings,
      investments: widget.investments,
    );
    final segments = (_showTarget ? rec.target : rec.current);
    final donutSegments = [
      for (final s in segments)
        if (s.pct > 0)
          FtDonutSegment(value: s.pct, color: s.color),
    ];

    if (rec.totalValue == 0) {
      return FtRefreshable(
        onRefresh: () async {
          ref.invalidate(currentHouseholdProvider);
          await ftRefreshDelay();
        },
        child: ListView(
        padding:
            const EdgeInsets.fromLTRB(22, 16, 22, kFtFabClearance),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'Belum ada data aset untuk dialokasikan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: FtColors.ink3),
              ),
            ),
          ),
        ],
        ),
      );
    }

    return FtRefreshable(
      onRefresh: () async {
        ref.invalidate(currentHouseholdProvider);
        await ftRefreshDelay();
      },
      child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, kFtFabClearance),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        _AllocationCard(
          showTarget: _showTarget,
          onToggle: (v) {
            FtHaptics.select();
            setState(() => _showTarget = v);
          },
          segments: segments,
          donutSegments: donutSegments,
          summary: rec.summary,
        ),
        const SizedBox(height: 18),
        RebalanceMoves(rec: rec),
        const SizedBox(height: 14),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Rekomendasi bersifat indikatif. Bukan saran investasi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FtColors.ink4,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({
    required this.showTarget,
    required this.onToggle,
    required this.segments,
    required this.donutSegments,
    required this.summary,
  });
  final bool showTarget;
  final ValueChanged<bool> onToggle;
  final List<AllocationSegment> segments;
  final List<FtDonutSegment> donutSegments;
  final String summary;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Eyebrow('Alokasi Portofolio')),
              _Toggle(showTarget: showTarget, onToggle: onToggle),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FtDonut(segments: donutSegments, size: 130, thickness: 18),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in segments) ...[
                      _LegendRow(segment: s),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FtColors.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FtColors.line, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.eco_outlined, size: 12, color: FtColors.moss),
                    const SizedBox(width: 6),
                    const Eyebrow('Ringkasan'),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  summary,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontSize: 13,
                    fontFamily: 'Geist',
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.showTarget, required this.onToggle});
  final bool showTarget;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FtColors.line, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'Sekarang',
            active: !showTarget,
            onTap: () => onToggle(false),
          ),
          _ToggleButton(
            label: 'Target',
            active: showTarget,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? FtColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? FtColors.bg : FtColors.ink2,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.segment});
  final AllocationSegment segment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: segment.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            segment.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: FtColors.ink2, fontSize: 11),
          ),
        ),
        Text(
          '${segment.pct.round()}%',
          style: TextStyle(
            color: FtColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
