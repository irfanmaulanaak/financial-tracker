import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../expenses/expense.dart';
import '../../household/household.dart';
import '../insights_providers.dart';

/// Total ZISWAF: siklus terpilih + tahun berjalan.
class RecapZiswafCard extends ConsumerWidget {
  const RecapZiswafCard({
    super.key,
    required this.household,
    required this.cycleTotal,
  });

  final Household household;
  final int cycleTotal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearList =
        ref.watch(ziswafYearExpensesProvider).value ?? const <Expense>[];
    final yearTotal = yearList.fold<int>(0, (a, e) => a + e.amount);
    final year = DateTime.now().year;
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism_rounded,
                  size: 18, color: FtColors.moss),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Zakat, infak, sedekah & wakaf',
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow('Siklus ini'),
                    const SizedBox(height: 2),
                    Text(
                      Money.format(cycleTotal),
                      style: TextStyle(
                        color: FtColors.ink,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow('Total $year'),
                    const SizedBox(height: 2),
                    Text(
                      Money.format(yearTotal),
                      style: TextStyle(
                        color: FtColors.moss,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
