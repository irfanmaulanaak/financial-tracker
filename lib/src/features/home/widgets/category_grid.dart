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
          title: 'Pengeluaran siklus ini',
          actionLabel: 'Lihat semua',
          onAction: onTap,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: GridView.count(
            crossAxisCount: context.isAtLeastExpanded
                ? 4
                : context.isAtLeastMedium
                    ? 3
                    : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            // 1.45 left cells ~1px short of the content's min height at
            // some widths (debug "BOTTOM OVERFLOWED BY 0.8 PIXELS" stripes).
            childAspectRatio: 1.25,
            children: [
              for (var i = 0; i < categories.length; i++)
                FtListReveal(
                  index: i,
                  child: _CategoryCell(
                    category: categories[i],
                    spent: totals[categories[i].id] ?? 0,
                    carry: carries[categories[i].id] ?? 0,
                  ),
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
    final hasBudget = budget > 0;
    final pct = hasBudget ? (spent / budget * 100).round() : 0;
    final over = hasBudget && spent > budget;
    // One neutral surface for every tile — the category color only shows in
    // the small icon tile, not the whole card (that made over-budget tiles
    // read as just "another pastel", not clearly red).
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: FtColors.tileFor(color),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(iconFor(category.icon), size: 13, color: color),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
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
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (hasBudget) ...[
            FtProgressBar(
              value: spent,
              max: budget,
              color: over ? FtColors.danger : FtColors.ink,
              overflowColor: FtColors.danger,
              trackColor: FtColors.surface,
              height: 8,
            ),
            const SizedBox(height: 5),
            Text(
              '$pct% terpakai',
              style: TextStyle(
                color: over ? FtColors.danger : FtColors.ink2,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else
            Text(
              'tanpa budget',
              style: TextStyle(
                color: FtColors.ink4,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
