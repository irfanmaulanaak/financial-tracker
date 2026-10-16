import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/budget_move.dart';
import '../../core/expense_aggregations.dart';
import '../../core/money_date.dart';
import '../../core/payday.dart';
import '../../core/recurring.dart';
import '../../core/recurring_runner.dart';
import '../../core/reminder_times.dart';
import '../../core/upcoming.dart';
import '../../theme.dart';
import '../../ui/ft_celebrate.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_ui.dart';
import '../cards/cards_screen.dart';
import '../cards/credit_card.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../incomes/income.dart';
import '../incomes/income_providers.dart';
import '../obligations/obligation_repository.dart';
import 'insights_providers.dart';
import 'widgets/money_date_steps.dart';

export 'widgets/money_date_steps.dart';

/// "Money Date" — review siklus terpandu ±7 menit, 4 langkah, maks 1
/// keputusan (riset: pasangan yang rutin review bersama melaporkan ~40%
/// lebih sedikit konflik uang; mulai dari yang berhasil, bukan yang gagal).
class MoneyDateScreen extends ConsumerStatefulWidget {
  const MoneyDateScreen({super.key});

  @override
  ConsumerState<MoneyDateScreen> createState() => _MoneyDateScreenState();
}

class _MoneyDateScreenState extends ConsumerState<MoneyDateScreen> {
  final _page = PageController();
  int _step = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    FtHaptics.select();
    if (_step >= 3) {
      FtCelebrate.show(context, message: 'Money date selesai.');
      context.pop();
      return;
    }
    _page.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final now = DateTime.now();
    final cycle = currentCycle(now, payday: household.payday);
    final expenses =
        ref.watch(cycleExpensesProvider).value ?? const <Expense>[];
    final prevCycles = ref.watch(previousCyclesExpensesProvider(1)).value ??
        const <List<Expense>>[];
    final baseline =
        prevCycles.isNotEmpty ? prevCycles[0] : const <Expense>[];
    final incomes =
        ref.watch(cycleIncomesProvider).value ?? const <Income>[];

    final invIds = household.investmentCategoryIds;
    List<ExpenseRecord> records(List<Expense> src) => [
          for (final e in src)
            ExpenseRecord(
              amount: e.amount,
              categoryId: e.categoryId,
              spentBy: e.spentBy,
              date: e.date,
            ),
        ];
    final cur = consumptionOnly(records(expenses), invIds);
    final base = consumptionOnly(records(baseline), invIds);
    final deltas = categoryDeltas(spentByCategory(cur), spentByCategory(base));
    final savers = topSavers(deltas);
    final risers = topRisers(deltas);
    final spent = totalSpent(cur);
    final earned = incomes.fold<int>(0, (a, b) => a + b.amount);

    // Tagihan 7 hari ke depan (kartu + tagihan rutin).
    final cards =
        ref.watch(cardsProvider(household.id)).value ?? const <CreditCard>[];
    final recurring =
        ref.watch(recurringExpensesYearProvider).value ?? const <Expense>[];
    final latest = latestPerKey<Expense>(
      recurring,
      keyOf: expenseTemplateKey,
      dateOf: (e) => e.date,
      isRecurring: (e) => e.recurring,
    );
    final upcoming = upcomingItems(
      cards: [
        for (final c in cards)
          (label: c.label, billingDay: c.billingDay, used: c.used),
      ],
      bills: [
        for (final e in recurring)
          if (latest[expenseTemplateKey(e)] == e.date)
            (
              title: (e.note?.isNotEmpty ?? false)
                  ? e.note!
                  : (household.categoryOf(e.categoryId)?.label ?? 'Tagihan'),
              nextDate: nextMonthlyOccurrence(e.date),
              amount: e.amount,
            ),
        for (final o in ref.watch(obligationsProvider).value ?? const [])
          if (!o.isComplete && !o.paidForMonth(nextCardDueDate(o.dueDay, now)))
            (
              title: o.label,
              nextDate: nextCardDueDate(o.dueDay, now),
              amount: o.monthly,
            ),
      ],
      now: now,
    );

    final moves = movesInCycle(
      household.budgetMoves,
      start: cycle.start,
      endExclusive: cycle.endExclusive,
    );
    final overCategory = _mostOverCategory(household, deltas);

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        child: FtPageContainer(
          child: Column(
            children: [
              FtSubHeader(
                title: 'Money Date',
                trailing: Text(
                  'Langkah ${_step + 1}/4',
                  style: TextStyle(color: FtColors.ink3, fontSize: 12),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _step = i),
                  children: [
                    MoneyDateStepScaffold(
                       eyebrow: 'Langkah 1: Rayakan dulu',
                      title: savers.isEmpty
                          ? 'Siklus berjalan.'
                          : 'Ada kategori yang dihemat.',
                      child: MoneyDateCelebrateStep(
                        household: household,
                        savers: savers,
                        earned: earned,
                        spent: spent,
                      ),
                    ),
                    MoneyDateStepScaffold(
                       eyebrow: 'Langkah 2: Sorotan',
                      title: risers.isEmpty
                          ? 'Tidak ada lonjakan berarti.'
                          : 'Dua kategori naik paling banyak.',
                      child: MoneyDateRisersStep(
                          household: household, risers: risers),
                    ),
                    MoneyDateStepScaffold(
                       eyebrow: 'Langkah 3: Lihat ke depan',
                      title: upcoming.isEmpty
                          ? '7 hari ke depan aman.'
                          : 'Tagihan 7 hari ke depan.',
                      child: MoneyDateUpcomingStep(items: upcoming),
                    ),
                    MoneyDateStepScaffold(
                       eyebrow: 'Langkah 4: Satu keputusan',
                      title: 'Cukup satu keputusan kecil.',
                      child: MoneyDateDecisionStep(
                        household: household,
                        moves: moves,
                        overCategoryId: overCategory,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: Row(
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: i == _step ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: i == _step
                              ? FtColors.clay
                              : FtColors.lineStrong,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _next,
                      child: Text(_step >= 3 ? 'Selesai' : 'Lanjut'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kategori paling kelebihan budget (target default tombol geser).
  String? _mostOverCategory(Household h, List<CategoryDelta> deltas) {
    String? worst;
    var worstGap = 0;
    for (final d in deltas) {
      final cat = h.categoryOf(d.id);
      if (cat == null || cat.archived || cat.monthlyBudget <= 0) continue;
      final gap = d.spend - cat.monthlyBudget;
      if (gap > worstGap) {
        worstGap = gap;
        worst = d.id;
      }
    }
    return worst;
  }
}
