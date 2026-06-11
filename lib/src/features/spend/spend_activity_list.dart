import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../home/widgets/recent_list.dart';
import '../household/household.dart';

/// "Aktivitas" below the category breakdown on `/spend` — every transaction
/// of the selected cycle, newest first. Rows open the expense detail sheet.
class SpendActivityList extends StatelessWidget {
  const SpendActivityList({
    super.key,
    required this.expenses,
    required this.household,
  });

  /// Already filtered to the cycle picked in the period chips.
  final List<Expense> expenses;
  final Household household;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) return const SizedBox.shrink();
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 8),
          child: Eyebrow('Aktivitas · ${sorted.length} Transaksi'),
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < sorted.length; i++)
                ExpenseActivityRow(
                  expense: sorted[i],
                  category: household.categoryOf(sorted[i].categoryId),
                  spender: household.memberOf(sorted[i].spentBy),
                  showTopBorder: i > 0,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
