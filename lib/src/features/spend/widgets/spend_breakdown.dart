import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_donut.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../../household/household.dart';

class SpendHero extends StatelessWidget {
  const SpendHero({
    super.key,
    required this.total,
    required this.displayAmount,
    required this.invested,
    required this.caption,
    required this.segments,
    required this.prevIndex,
    required this.cycleRanges,
    required this.cycleShortLabels,
    required this.onPick,
  });
  final int total;
  final int displayAmount;

  /// Investment-category spend this period — shown as a note, not counted
  /// in [total].
  final int invested;
  final String caption;
  final List<FtDonutSegment> segments;
  final int? prevIndex;

  /// Compact "25 Apr–24 Mei" labels, index 0 = most recent previous cycle.
  /// Used only for the siklus caption above the total, not the period chips.
  final List<String> cycleRanges;

  /// Short "Jul"/"Agu"/"Sep" labels for the period chips, same index order
  /// as [cycleRanges] — all the same font size, so chips never look cramped.
  final List<String> cycleShortLabels;
  final ValueChanged<int?> onPick;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(_periodLabel(prevIndex)),
                    const SizedBox(height: 4),
                    FtFadeUp(
                      duration: const Duration(milliseconds: 360),
                      distance: 6,
                      child: Text(
                        compactMoney(displayAmount),
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(
                                fontSize: 34,
                                letterSpacing: -0.8,
                                fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      caption,
                      style:
                          TextStyle(color: FtColors.ink3, fontSize: 11),
                    ),
                    if (invested > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+ ${compactMoney(invested)} ke investasi '
                        '(tidak dihitung)',
                        style: TextStyle(
                          color: FtColors.moss,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              FtDonut(segments: segments, size: 116, thickness: 14),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: FtColors.line, height: 1),
          const SizedBox(height: 12),
          _PeriodPicker(
            prevIndex: prevIndex,
            cycleShortLabels: cycleShortLabels,
            onPick: onPick,
          ),
        ],
      ),
    );
  }

  String _periodLabel(int? idx) {
    if (idx == null) return 'Siklus berjalan · Total';
    final range = idx < cycleRanges.length ? ' (${cycleRanges[idx]})' : '';
    return '${idx + 1} siklus lalu$range · Total';
  }
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({
    required this.prevIndex,
    required this.cycleShortLabels,
    required this.onPick,
  });
  final int? prevIndex;
  final List<String> cycleShortLabels;
  final ValueChanged<int?> onPick;

  @override
  Widget build(BuildContext context) {
    // Render oldest → newest: prev2, prev1, prev0, current.
    final options = <(int?, String)>[
      for (var i = cycleShortLabels.length - 1; i >= 0; i--)
        (i, cycleShortLabels[i]),
      (null, 'Sekarang'),
    ];
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          Expanded(
            child: _PeriodChip(
              label: options[i].$2,
              active: options[i].$1 == prevIndex,
              onTap: () => onPick(options[i].$1),
            ),
          ),
          if (i != options.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.97,
      onTap: active ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
        decoration: BoxDecoration(
          color: active ? FtColors.ink : FtColors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: active ? null : Border.all(color: FtColors.line),
        ),
        alignment: Alignment.center,
        // Short labels ("Jul", "Sekarang") fit at a fixed size — every chip
        // reads at the same font size, unlike the old full date ranges.
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: active ? FtColors.bg : FtColors.ink2,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class SpendCategoryRow extends StatelessWidget {
  const SpendCategoryRow({
    super.key,
    required this.category,
    required this.spent,
    required this.carry,
    required this.total,
    required this.focused,
    required this.canEditBudget,
    required this.onTap,
    required this.onEditBudget,
    required this.onHover,
  });
  final Category category;
  final int spent;

  /// Rollover carry from the previous cycle (0 when off / not applicable).
  final int carry;
  final int total;
  final bool focused;
  final bool canEditBudget;
  final VoidCallback onTap;
  final VoidCallback onEditBudget;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0.0 : (spent / total) * 100;
    final budget = category.monthlyBudget + carry;
    final overBudget = budget > 0 && spent > budget;
    final color = parseColor(category.color);
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: FtTapScale(
        scale: 0.99,
        haptic: false,
        onTap: onTap,
        child: Container(
          color: focused ? FtColors.surfaceAlt : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: FtColors.tileFor(color),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(iconFor(category.icon), size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            category.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: FtColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          compactMoney(spent),
                          style: TextStyle(
                            color: FtColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: FtColors.ink3,
                            fontSize: 10,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          overBudget
                              ? '+${(((spent / budget) - 1) * 100).round()}% vs anggaran'
                              : budget > 0
                                  ? 'dari ${Money.format(budget)}${carry > 0 ? ' (gulir +${compactMoney(carry)})' : ''}'
                                  : 'tanpa budget',
                          style: TextStyle(
                            color:
                                overBudget ? FtColors.danger : FtColors.ink3,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canEditBudget)
                _BudgetMenu(onEdit: onEditBudget)
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: FtColors.ink4,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetMenu extends StatelessWidget {
  const _BudgetMenu({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Aksi',
      icon: Icon(Icons.more_vert_rounded, size: 18, color: FtColors.ink3),
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v == 'budget') onEdit();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'budget',
          child: Text('Atur anggaran'),
        ),
      ],
    );
  }
}
