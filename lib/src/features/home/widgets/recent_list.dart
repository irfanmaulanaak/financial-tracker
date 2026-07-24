import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../expenses/expense.dart';
import '../../expenses/expense_detail_sheet.dart';
import '../../household/household.dart';
import '../../members/member_chip.dart';
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
    return Column(
      children: [
        FtSectionHeader(
          title: 'Aktivitas Terbaru',
          actionLabel: 'Lihat semua',
          onAction: onTap,
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          decoration: BoxDecoration(
            color: FtColors.surface,
            border: Border.all(color: FtColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: recentAsync.maybeWhen(
              data: (recent) => recent.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Belum ada pengeluaran tercatat siklus ini.',
                              style: TextStyle(
                                color: FtColors.ink3,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/expenses/new'),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text(
                                'Catat pengeluaran pertama',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  : [
                      for (var i = 0; i < recent.length; i++)
                        ExpenseActivityRow(
                          expense: recent[i],
                          category: household.categoryOf(recent[i].categoryId),
                          spender: household.memberOf(recent[i].spentBy),
                          showTopBorder: i > 0,
                        ),
                    ],
              orElse: () => const [
                Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Single expense row (icon, category, date · note, spender chip, amount).
/// Tap opens [ExpenseDetailSheet]. Shared by the home "Aktivitas Terbaru"
/// list and the spend screen activity list.
class ExpenseActivityRow extends StatelessWidget {
  const ExpenseActivityRow({
    super.key,
    required this.expense,
    required this.category,
    required this.spender,
    this.showTopBorder = true,
  });

  final Expense expense;
  final Category? category;
  final Member? spender;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final color = category != null
        ? parseColor(category!.color)
        : FtColors.ink3;
    return FtTapScale(
      scale: 0.99,
      onTap: () => ExpenseDetailSheet.show(context: context, expense: expense),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          border: showTopBorder
              ? Border(top: BorderSide(color: FtColors.line))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Icon(
                iconFor(category?.icon ?? 'category'),
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          [
                            Dates.short(expense.date),
                            if (expense.note != null &&
                                expense.note!.isNotEmpty)
                              expense.note!,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: FtColors.ink3,
                            fontSize: 11,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (spender != null) ...[
                        const SizedBox(width: 6),
                        MemberChip(member: spender!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              compactMoney(expense.amount),
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
