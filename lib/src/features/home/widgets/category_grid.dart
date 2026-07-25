import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household.dart';
import 'home_formatters.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.totals,
    this.carries = const {},
    required this.onTap,
  });

  final List<Category> categories;
  final Map<String, int> totals;

  /// Per-category rollover carry from last cycle (only for rollover
  /// categories; missing = 0).
  final Map<String, int> carries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        FtSectionHeader(
          title: 'Pengeluaran Siklus Ini',
          actionLabel: 'Lihat semua',
          onAction: onTap,
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: GridView.count(
            crossAxisCount: context.isAtLeastExpanded
                ? 4
                : context.isAtLeastMedium
                    ? 3
                    : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            // 1.45 left cells ~1px short of the content's min height at
            // some widths (debug "BOTTOM OVERFLOWED BY 0.8 PIXELS" stripes).
            childAspectRatio: 1.38,
            children: [
              for (final c in categories)
                _CategoryCell(
                  category: c,
                  spent: totals[c.id] ?? 0,
                  carry: carries[c.id] ?? 0,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.category,
    required this.spent,
    this.carry = 0,
  });

  final Category category;
  final int spent;
  final int carry;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(category.color);
    final budget = category.monthlyBudget + carry;
    final pct = budget > 0 ? (spent / budget * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FtColors.line, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconFor(category.icon), size: 15, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink2,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            compactMoney(spent),
            style: TextStyle(
              color: FtColors.ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          FtProgressBar(
            value: spent,
            max: budget <= 0 ? 1 : budget,
            color: color,
            overflowColor: FtColors.danger,
            height: 3,
          ),
          const SizedBox(height: 5),
          Text(
            budget > 0 ? '$pct% terpakai' : 'tanpa budget',
            style: TextStyle(
              color: budget > 0 && spent > budget
                  ? FtColors.danger
                  : FtColors.ink3,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
