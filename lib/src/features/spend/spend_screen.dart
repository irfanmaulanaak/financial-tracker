import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/envelope.dart';
import '../../core/expense_aggregations.dart';
import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../../theme.dart';
import '../../ui/ft_donut.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../insights/insights_providers.dart';
import 'budget_edit_sheet.dart';
import 'spend_activity_list.dart';
import 'spend_calendar.dart';
import 'widgets/spend_breakdown.dart';

export 'widgets/spend_breakdown.dart';

/// "Pengeluaran Bulanan" — donut + category breakdown drilldown.
/// Mirrors `claude-design/screens-deep.jsx` `SpendScreen`. Tapping a category
/// row navigates to that category's detail page.
class SpendScreen extends ConsumerStatefulWidget {
  const SpendScreen({super.key});

  @override
  ConsumerState<SpendScreen> createState() => _SpendScreenState();
}

class _SpendScreenState extends ConsumerState<SpendScreen> {
  /// `null` = current cycle, otherwise index into the previous-cycles list.
  int? _prevIndex;
  String? _focusedCategoryId;

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cycleAsync = ref.watch(cycleExpensesProvider);
    final prevAsync = ref.watch(previousCyclesExpensesProvider(3));
    final cycleExpenses = cycleAsync.value ?? const <Expense>[];
    final prevCycles = prevAsync.value ?? const <List<Expense>>[];

    final List<Expense> active = _prevIndex == null
        ? cycleExpenses
        : (prevCycles.length > _prevIndex! ? prevCycles[_prevIndex!] : const []);

    final records = [
      for (final e in active)
        ExpenseRecord(
          amount: e.amount,
          categoryId: e.categoryId,
          spentBy: e.spentBy,
          date: e.date,
        ),
    ];
    // Total + donut count consumption only; investment-category expenses
    // are surfaced separately (note under the total + activity list).
    final spendRecords =
        consumptionOnly(records, household.investmentCategoryIds);
    final total = totalSpent(spendRecords);
    final invested = totalSpent(records) - total;
    final byCat = spentByCategory(spendRecords);
    final categories = household.categories
        .where((c) => !c.archived)
        .toList()
      ..sort((a, b) {
        final sa = byCat[a.id] ?? 0;
        final sb = byCat[b.id] ?? 0;
        if (sa != sb) return sb.compareTo(sa);
        return a.sortOrder.compareTo(b.sortOrder);
      });

    final focused = _focusedCategoryId == null
        ? null
        : categories.firstWhere(
            (c) => c.id == _focusedCategoryId,
            orElse: () => categories.first,
          );
    final focusedAmount =
        focused == null ? null : (byCat[focused.id] ?? 0);

    // Rollover carry only applies when looking at the *current* cycle;
    // historical views use the plain budget.
    final prevByCat = _prevIndex == null && prevCycles.isNotEmpty
        ? spentByCategory([
            for (final e in prevCycles[0])
              ExpenseRecord(
                amount: e.amount,
                categoryId: e.categoryId,
                spentBy: e.spentBy,
                date: e.date,
              ),
          ])
        : const <String, int>{};
    int carryOf(Category c) => _prevIndex == null && c.rollover
        ? carryOver(
            monthlyBudget: c.monthlyBudget,
            prevCycleSpent: prevByCat[c.id] ?? 0,
          )
        : 0;

    // Date-range labels for the period chips, walking back from the current
    // cycle start the same way `previousCyclesExpensesProvider` builds its
    // windows (index 0 = most recent previous cycle).
    final cycle = currentCycle(DateTime.now(), payday: household.payday);
    final cycleRanges = <String>[];
    final cycleShortLabels = <String>[];
    var cursor = cycle.start;
    for (var i = 0; i < prevCycles.length; i++) {
      final prevStart =
          resolvePayday(cursor.year, cursor.month - 1, household.payday);
      cycleRanges.add(Dates.cycleRange(prevStart, cursor));
      cycleShortLabels.add(Dates.monthShort(prevStart));
      cursor = prevStart;
    }

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.spend,
        child: FtRefreshable(
          onRefresh: () async {
            ref.invalidate(currentHouseholdProvider);
            ref.invalidate(cycleExpensesProvider);
            ref.invalidate(previousCyclesExpensesProvider);
            await ftRefreshDelay();
          },
          child: ListView(
          padding: const EdgeInsets.only(bottom: kFtFabClearance),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            const FtSubHeader(title: 'Pengeluaran', isTab: true),
            SpendHero(
              total: total,
              displayAmount: focusedAmount ?? total,
              invested: invested,
              caption: focused != null
                  ? focused.label
                  : 'Total ${categories.length} kategori aktif',
              segments: [
                for (final c in categories.where((c) => (byCat[c.id] ?? 0) > 0))
                  FtDonutSegment(
                    value: (byCat[c.id] ?? 0).toDouble(),
                    color: parseColor(c.color),
                  ),
              ],
              prevIndex: _prevIndex,
              cycleRanges: cycleRanges,
              cycleShortLabels: cycleShortLabels,
              onPick: (i) {
                setState(() {
                  _prevIndex = i;
                  _focusedCategoryId = null;
                });
              },
            ),
            const SizedBox(height: 18),
            const FtSectionHeader(title: 'Rincian kategori'),
            FtCard(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (categories.where((c) => (byCat[c.id] ?? 0) > 0).isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Text(
                        'Belum ada pengeluaran pada periode ini.',
                        style: TextStyle(color: FtColors.ink3, fontSize: 12),
                      ),
                    )
                  else
                    for (var i = 0;
                        i < categories.length;
                        i++) ...[
                      if ((byCat[categories[i].id] ?? 0) <= 0)
                        const SizedBox.shrink()
                      else ...[
                        if (i > 0) const Divider(height: 1),
                        SpendCategoryRow(
                          category: categories[i],
                          spent: byCat[categories[i].id] ?? 0,
                          carry: carryOf(categories[i]),
                          total: total,
                          focused:
                              _focusedCategoryId == categories[i].id,
                          canEditBudget:
                              ref.watch(canRecordTxnProvider),
                          onTap: () =>
                              context.push('/categories/${categories[i].id}'),
                          onEditBudget: () => BudgetEditSheet.show(
                            context: context,
                            category: categories[i],
                          ),
                          onHover: (entered) => setState(() {
                            _focusedCategoryId =
                                entered ? categories[i].id : null;
                          }),
                        ),
                      ],
                    ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            const FtSectionHeader(title: 'Pengeluaran harian'),
            const SpendCalendar(),
            SpendActivityList(expenses: active, household: household),
          ],
        ),
        ),
      ),
    );
  }
}
