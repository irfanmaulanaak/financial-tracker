import 'package:flutter/material.dart';

import '../../../core/expense_aggregations.dart';
import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart' show compactMoney;
import '../../household/household.dart';

class RecapStat extends StatelessWidget {
  const RecapStat({super.key, required this.label, required this.value, this.color});
  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label),
          const SizedBox(height: 4),
          // Compact money ("Rp49,2 jt") instead of the full grouped amount —
          // three full amounts in one row ran into each other at 360px.
          Text(
            compactMoney(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 17,
                  color: color ?? FtColors.ink,
                ),
          ),
        ],
      ),
    );
  }
}

class RecapCycleChip extends StatelessWidget {
  const RecapCycleChip({
    super.key,
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
      scale: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? FtColors.ink : FtColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? FtColors.ink : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : FtColors.ink2,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class RecapCategoryDeltaTile extends StatelessWidget {
  const RecapCategoryDeltaTile({
    super.key,
    required this.category,
    required this.spend,
    required this.baseline,
    required this.baselineLabel,
  });
  final Category? category;
  final int spend;
  final int baseline;
  final String baselineLabel;

  @override
  Widget build(BuildContext context) {
    final (deltaText, deltaColor) = switch ((baseline, spend - baseline)) {
      (0, _) => ('baru siklus ini', FtColors.ink3),
      (_, final d) when d > 0 => (
          '+${(d * 100 / baseline).round()}% vs $baselineLabel',
          FtColors.ochre,
        ),
      (_, final d) when d < 0 => (
          '−${(d.abs() * 100 / baseline).round()}% vs $baselineLabel',
          FtColors.sage,
        ),
      _ => ('sama dengan siklus lalu', FtColors.ink3),
    };
    final color = category != null
        ? Color(int.parse('FF${category!.color.replaceFirst('#', '')}',
            radix: 16))
        : FtColors.ink3;

    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.label ?? '-',
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deltaText,
                  style: TextStyle(color: deltaColor, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            Money.format(spend),
            style: TextStyle(
              color: FtColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class RecapBiggestTile extends StatelessWidget {
  const RecapBiggestTile({
    super.key,
    required this.record,
    required this.household,
    required this.note,
  });
  final ExpenseRecord record;
  final Household household;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final cat = household.categoryOf(record.categoryId);
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (note?.isNotEmpty ?? false) ? note! : (cat?.label ?? '-'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${cat?.label ?? '-'} · ${Dates.short(record.date)}',
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            Money.format(record.amount),
            style: TextStyle(
              color: FtColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
