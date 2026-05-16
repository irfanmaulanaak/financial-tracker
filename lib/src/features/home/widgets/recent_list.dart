import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../expenses/expense.dart';
import '../../household/household.dart';
import '../../household/name_format.dart';
import 'home_formatters.dart';

class RecentList extends StatelessWidget {
  const RecentList({
    super.key,
    required this.recentAsync,
    required this.household,
    required this.onTap,
  });

  final AsyncValue<List<Expense>> recentAsync;
  final Household household;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              children: [
                const Expanded(child: Eyebrow('Aktivitas Terbaru')),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Lihat semua',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          ...recentAsync.maybeWhen(
            data: (recent) => recent.isEmpty
                ? [
                    Padding(
                      padding: EdgeInsets.fromLTRB(18, 12, 18, 18),
                      child: Text(
                        'Belum ada pengeluaran.',
                        style: TextStyle(color: FtColors.ink3, fontSize: 12),
                      ),
                    ),
                  ]
                : [
                    for (final e in recent)
                      _RecentExpenseRow(
                        expense: e,
                        category: household.categoryOf(e.categoryId),
                        spender: household.memberOf(e.spentBy),
                      ),
                  ],
            orElse: () => const [
              Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentExpenseRow extends StatelessWidget {
  const _RecentExpenseRow({
    required this.expense,
    required this.category,
    required this.spender,
  });

  final Expense expense;
  final Category? category;
  final Member? spender;

  @override
  Widget build(BuildContext context) {
    final color = category != null
        ? parseColor(category!.color)
        : FtColors.ink3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: FtColors.line, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(
              iconFor(category?.icon ?? 'category'),
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.label ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    Dates.short(expense.date),
                    if (expense.note != null && expense.note!.isNotEmpty)
                      expense.note!,
                    if (spender != null) prettyName(spender!.displayName),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            compactMoney(expense.amount),
            style: TextStyle(
              color: FtColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
