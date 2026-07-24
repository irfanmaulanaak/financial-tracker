import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hide_assets_provider.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';

/// Top "Total Aset" card on the Aset screen — big total, divider,
/// 3-segment composition bar, and a 3-column breakdown row beneath it.
class AssetsHero extends ConsumerWidget {
  const AssetsHero({
    super.key,
    required this.cash,
    required this.savings,
    required this.investments,
    required this.total,
  });
  final int cash;
  final int savings;
  final int investments;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideAssetsProvider);
    return FtCard(
      heroTag: 'ft-aset-hero',
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 14),
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
          const SizedBox(height: 6),
          FtFadeUp(
            duration: const Duration(milliseconds: 380),
            distance: 6,
            child: Text.rich(
              TextSpan(
                text: hidden ? '•••• ' : moneyNoSymbol(total),
                children: [
                  TextSpan(
                    text: ' IDR',
                    style: TextStyle(
                      fontSize: 13,
                      color: FtColors.ink3,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 38,
                    height: 1,
                    letterSpacing: -1.3,
                    fontWeight: FontWeight.w500,
                    color: FtColors.ink,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: FtColors.line, height: 1),
          const SizedBox(height: 14),
          _CompositionBar(
            cash: cash,
            savings: savings,
            investments: investments,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CompositionStat(
                label: 'Tunai',
                value: cash,
                color: FtColors.sky,
                hidden: hidden,
              ),
              _CompositionStat(
                label: 'Tabungan',
                value: savings,
                color: FtColors.moss,
                hidden: hidden,
              ),
              _CompositionStat(
                label: 'Investasi',
                value: investments,
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

class _CompositionBar extends StatelessWidget {
  const _CompositionBar({
    required this.cash,
    required this.savings,
    required this.investments,
  });
  final int cash;
  final int savings;
  final int investments;

  @override
  Widget build(BuildContext context) {
    final total = cash + savings + investments;
    if (total <= 0) {
      return SizedBox(
        height: 8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(color: FtColors.line),
        ),
      );
    }
    int flex(int v) => (v / total * 1000).round().clamp(0, 1000);
    final segments = [
      if (cash > 0)
        Expanded(flex: flex(cash), child: Container(color: FtColors.sky)),
      if (savings > 0)
        Expanded(flex: flex(savings), child: Container(color: FtColors.moss)),
      if (investments > 0)
        Expanded(
            flex: flex(investments), child: Container(color: FtColors.clay)),
    ];
    return SizedBox(
      height: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(children: segments),
      ),
    );
  }
}

class _CompositionStat extends StatelessWidget {
  const _CompositionStat({
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
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: FtColors.ink3,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            hidden ? maskMoney() : compactMoney(value),
            style: TextStyle(
              color: FtColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
