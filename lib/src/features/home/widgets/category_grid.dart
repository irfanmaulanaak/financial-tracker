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
          prominent: true,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: Column(
            children: [
              for (var i = 0; i < categories.length; i++)
                _CategoryCell(
                  category: categories[i],
                  spent: totals[categories[i].id] ?? 0,
                  carry: carries[categories[i].id] ?? 0,
                  showDivider: i > 0,
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
    this.showDivider = false,
  });

  final Category category;
  final int spent;
  final int carry;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(category.color);
    final budget = category.monthlyBudget + carry;
    final pct = budget > 0 ? (spent / budget * 100).round() : 0;
    return Column(
      children: [
        if (showDivider)
          Divider(height: 1, thickness: 0.5, indent: 30, color: FtColors.line),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            children: [
              Icon(iconFor(category.icon), size: 18, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: FtColors.ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        Text(
                          budget > 0 ? '$pct%' : 'Tanpa budget',
                          style: TextStyle(
                            color: budget > 0 && spent > budget
                                ? FtColors.danger
                                : FtColors.ink3,
                            fontSize: 10.5,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FtProgressBar(
                      value: spent,
                      max: budget <= 0 ? 1 : budget,
                      color: color,
                      overflowColor: FtColors.danger,
                      height: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 72,
                child: Text(
                  compactMoney(spent),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
