import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_detail_sheet.dart';
import '../expenses/expense_repository.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household_providers.dart';
import '../insights/insights_providers.dart';
import 'widgets/category_detail_header_card.dart';

export 'widgets/category_detail_header_card.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});
  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final category = household.categoryOf(categoryId);
    if (category == null) {
      return Scaffold(
        backgroundColor: FtColors.bg,
        body: FtAppChrome(
          current: FtTab.spend,
          child: Column(
            children: [
              const FtSubHeader(title: 'Kategori'),
              Expanded(
                child: Center(
                  child: Text('Kategori tidak ditemukan.',
                      style: TextStyle(color: FtColors.ink3)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final cycle = currentCycle(DateTime.now(), payday: household.payday);
    final expensesAsync = ref.watch(
      _categoryExpensesProvider((hid: household.id, catId: categoryId)),
    );
    final prevAsync = ref.watch(previousCyclesExpensesProvider(3));

    final color = parseColor(category.color);

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.spend,
        child: FtRefreshable(
          onRefresh: () async {
            ref.invalidate(currentHouseholdProvider);
            ref.invalidate(_categoryExpensesProvider((hid: household.id, catId: categoryId)));
            ref.invalidate(previousCyclesExpensesProvider);
            await ftRefreshDelay();
          },
          child: ListView(
          padding: const EdgeInsets.only(bottom: kFtFabClearance),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            FtSubHeader(title: category.label),
            CategoryDetailHeaderCard(
              category: category,
              expensesAsync: expensesAsync,
              prevAsync: prevAsync,
              cycle: cycle,
              color: color,
              canMoveBudget: ref.watch(canWriteAllProvider),
            ),
            expensesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Gagal: $e')),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Belum ada pengeluaran di kategori ini.',
                        style: TextStyle(color: FtColors.ink3),
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(22, 14, 22, 8),
                      child: Eyebrow('Transaksi Terbaru'),
                    ),
                    for (final e in expenses)
                      FtCard(
                        margin: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        onTap: () => ExpenseDetailSheet.show(
                          context: context,
                          expense: e,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.note ?? category.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${Dates.short(e.date)}${e.note != null && e.note!.isNotEmpty ? ' · ${e.note}' : ''}',
                                    style: TextStyle(
                                      color: FtColors.ink3,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Money.format(e.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        ),
      ),
    );
  }
}

final _categoryExpensesProvider =
    StreamProvider.family<List<Expense>, ({String hid, String catId})>(
  (ref, p) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) return Stream.value(const []);
    final cycle = currentCycle(DateTime.now(), payday: household.payday);
    return ref
        .watch(expenseRepositoryProvider)
        .watchByCategory(
          householdId: p.hid,
          categoryId: p.catId,
          startInclusive: cycle.start,
          endExclusive: cycle.endExclusive,
        );
  },
);
