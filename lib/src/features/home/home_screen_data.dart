import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/daily_insight.dart';
import '../../core/disposable_income.dart';
import '../../core/envelope.dart';
import '../../core/expense_aggregations.dart';
import '../../core/formatters.dart';
import '../../core/health_score.dart';
import '../../core/in_app_indicators.dart';
import '../../core/net_worth.dart';
import '../../core/payday.dart';
import '../../core/providers.dart';
import '../../core/reminder_times.dart';
import '../../core/safe_to_spend.dart';
import '../../theme.dart';
import '../cards/credit_card.dart';
import '../cards/cards_screen.dart';
import '../cards/widgets/installment_list.dart' show cardInstallmentsProvider;
import '../household/household.dart';
import '../expenses/expense.dart';
import '../goals/goal.dart';
import '../goals/goals_screen.dart';
import '../incomes/income.dart';
import '../incomes/income_providers.dart';
import '../obligations/obligation_repository.dart';
import '../insights/insights_providers.dart';
import '../investments/investment.dart';
import '../investments/investments_repository.dart' show investmentsProvider;
import 'net_worth_snapshot.dart';
import 'net_worth_snapshot_repository.dart';
import 'widgets/banners.dart';
import 'widgets/home_formatters.dart' show compactMoney;

/// Everything the home screen's `build` needs to render, computed in one
/// place. Pure move of the former inline computation — same providers read
/// in the same order, same values produced.
typedef HomeViewData = ({
  List<Expense> expenses,
  List<Category> categories,
  Map<String, int> byCat,
  Map<String, int> carries,
  List<Goal> goals,
  NetWorth nw,
  List<double> trend,
  List<DateTime> trendDates,
  int cycleNet,
  int totalSpentValue,
  int gajiIncome,
  HealthScore health,
  ({
    int perDay,
    int remaining,
    int daysLeft,
    DateTime nextPayday,
    bool hasBudget,
  }) safe,
  String? insightCandidate,
  List<AttentionItem> attentionItems,
});

HomeViewData buildHomeViewData({
  required WidgetRef ref,
  required BuildContext context,
  required Household household,
  required AsyncValue<List<Expense>> cycleAsync,
}) {
  final user = ref.watch(authStateProvider).value;
  final cardsAsync = ref.watch(cardsProvider(household.id));
  final goalsAsync = ref.watch(fundedGoalsProvider(household.id));
  final investmentsAsync = ref.watch(investmentsProvider(household.id));

  final now = DateTime.now();
  final expenses = cycleAsync.value ?? const <Expense>[];
  final records = [
    for (final e in expenses)
      ExpenseRecord(
        amount: e.amount,
        categoryId: e.categoryId,
        spentBy: e.spentBy,
        date: e.date,
      ),
  ];
  // Totals count consumption only — investment-category expenses
  // are savings, not spending. Per-category grid stays complete.
  final invCatIds = household.investmentCategoryIds;
  final totalSpentValue = totalSpent(consumptionOnly(records, invCatIds));
  final income = ref.watch(currentCycleIncomeTotalProvider);
  final gajiIncome = (ref.watch(cycleIncomesProvider).value ?? const <Income>[])
      .where((i) => i.source == IncomeSource.salary)
      .fold<int>(0, (a, b) => a + b.amount);
  final byCat = spentByCategory(records);
  final categories = household.categories.where((c) => !c.archived).toList()
    ..sort((a, b) {
      final sa = byCat[a.id] ?? 0;
      final sb = byCat[b.id] ?? 0;
      if (sa != sb) return sb.compareTo(sa);
      return a.sortOrder.compareTo(b.sortOrder);
    });

  final cards = cardsAsync.value ?? const <CreditCard>[];
  final goals = goalsAsync.value ?? const <Goal>[];
  final investments = investmentsAsync.value ?? const <Investment>[];
  final prevAsync = ref.watch(previousCyclesExpensesProvider(3));
  final prevCycles = prevAsync.value ?? const <List<Expense>>[];
  final prevByCat = prevCycles.isEmpty
      ? const <String, int>{}
      : spentByCategory([
          for (final e in prevCycles[0])
            ExpenseRecord(
              amount: e.amount,
              categoryId: e.categoryId,
              spentBy: e.spentBy,
              date: e.date,
            ),
        ]);
  final carries = {
    for (final c in categories)
      if (c.rollover)
        c.id: carryOver(
          monthlyBudget: c.monthlyBudget,
          prevCycleSpent: prevByCat[c.id] ?? 0,
        ),
  };
  final avgPrev = prevCycles.isEmpty
      ? 0
      : prevCycles
                .map((w) => w
                    .where((e) => !invCatIds.contains(e.categoryId))
                    .fold<int>(0, (a, b) => a + b.amount))
                .fold<int>(0, (a, b) => a + b) ~/
            prevCycles.length;
  final obligations = ref.watch(obligationsProvider).value ?? const [];
  final activeObligations = obligations.where((o) => !o.isComplete).toList();
  final debtMonthly = activeObligations
      .where((o) => o.isDebt)
      .fold<int>(0, (a, o) => a + o.monthly);
  final nonDebtMonthly = activeObligations
      .where((o) => !o.isDebt)
      .fold<int>(0, (a, o) => a + o.monthly);
  // Semua obligation utang, termasuk yang tenornya tamat — pokok
  // positif tetap utang riil sampai user menolkannya.
  final obligationsPrincipal = obligations
      .where((o) => o.isDebt)
      .fold<int>(0, (a, o) => a + (o.outstandingPrincipal ?? 0));
  final invTotal = investments.fold<int>(0, (a, i) => a + i.currentValue);
  final nw = computeNetWorth(
    cash: [
      for (final a in household.cashAccounts)
        AccountBalance(id: a.id, label: a.label, value: a.value),
    ],
    savings: [
      for (final a in household.savingsAccounts)
        AccountBalance(id: a.id, label: a.label, value: a.value),
    ],
    cards: [
      for (final c in cards)
        CardBalance(
          id: c.id,
          label: c.label,
          limit: c.limit,
          // Net worth counts the true obligation (full unpaid cicilan
          // remainder), not the statement-day `used` figure — so the
          // chart doesn't jump on tanggal cetak.
          used: c.outstanding,
        ),
    ],
    investments: invTotal,
    otherDebt: obligationsPrincipal,
  );
  final assets = householdAssetsAndDebt(
    household,
    cards.map((c) => (limit: c.limit, used: c.outstanding)),
  );
  // Record today's net-worth snapshot once everything's loaded.
  // Idempotent per day (see [NetWorthSnapshotRepository.recordToday]).
  if (user != null &&
      cardsAsync.hasValue == true &&
      investmentsAsync.hasValue == true) {
    // ignore: discarded_futures
    ref.read(netWorthSnapshotRepositoryProvider).recordToday(
          householdId: household.id,
          nw: nw,
          capturedBy: user.uid,
        );
  }
  final history = ref.watch(netWorthHistoryProvider(14)).value ??
      const <NetWorthSnapshot>[];
  // One point per calendar day (carry-forward over unopened days) so
  // the sparkline's x-axis is real time and scrubbing maps to dates.
  final dailySeries = fillDailyNetWorthSeries(history);
  final trend = [for (final p in dailySeries) p.total.toDouble()];
  final trendDates = [for (final p in dailySeries) p.date];
  final health = computeHealthScore(
    HealthScoreInputs(
      spendThisCycle: totalSpentValue,
      incomeThisCycle: income,
      monthlyBudget: household.monthlyBudgetTotal,
      savingsBalance: assets.savingsBalance,
      cardDebt: assets.cardDebt + obligationsPrincipal,
      avgMonthlySpend: avgPrev,
      investmentCount: investments.where((i) => i.currentValue > 0).length,
    ),
  );
  final dueItems = [
    for (final c in cards)
      if (daysUntilDue(dueDay: c.dueDay, now: now) case final d?)
        if (c.used > 0)
          AttentionItem(
            icon: Icons.credit_card_rounded,
            color: d <= 0 ? FtColors.danger : FtColors.ochre,
            text: d <= 0
                ? '${c.label} jatuh tempo hari ini · ${compactMoney(c.used)}'
                : '${c.label} jatuh tempo $d hari lagi · ${compactMoney(c.used)}',
            onTap: () => context.push('/cards'),
          ),
    for (final o in activeObligations)
      if (!o.paidForMonth(nextCardDueDate(o.dueDay, now)))
        if (daysUntilDue(dueDay: o.dueDay, now: now) case final d?)
          AttentionItem(
            icon: Icons.request_quote_rounded,
            color: d <= 0 ? FtColors.danger : FtColors.ochre,
            text: d <= 0
                ? '${o.label} jatuh tempo hari ini · ${compactMoney(o.monthly)}'
                : '${o.label} jatuh tempo $d hari lagi · ${compactMoney(o.monthly)}',
            onTap: () => context.push('/obligations'),
          ),
  ];

  // Insight 1 kalimat/hari — kandidat dihitung dari data terkini,
  // dikunci per-hari oleh DailyInsightLine.
  final cycleNow = currentCycle(now, payday: household.payday);
  final yesterdayKey = Dates.dayKey(now).subtract(const Duration(days: 1));
  final insightCandidate = dailyInsight(
    categories: [
      for (final c in categories)
        (
          id: c.id,
          label: c.label,
          budget: c.monthlyBudget + (carries[c.id] ?? 0),
          spent: byCat[c.id] ?? 0,
        ),
    ],
    prevSpentById: prevByCat,
    totalSpent: totalSpentValue,
    totalBudget: household.monthlyBudgetTotal,
    daysElapsed: Dates.dayKey(now).difference(cycleNow.start).inDays + 1,
    cycleLength: cycleLengthDays(cycleNow),
    noSpendYesterday: !cycleNow.start.isAfter(yesterdayKey) &&
        expenses.every((e) => Dates.dayKey(e.date) != yesterdayKey),
  );

  // Cycle net used by the asset slide's delta pill. Use Gaji-only
  // income so it matches the ratio slide (and what the user really
  // means by "earnings this cycle").
  final cycleNet = gajiIncome - totalSpentValue;

  // Slide "aman dibelanjakan": budget total (termasuk carry amplop)
  // − terpakai, dibagi hari tersisa sampai gajian.
  final carryTotal = carries.values.fold<int>(0, (a, b) => a + b);
  final budgetTotal = household.monthlyBudgetTotal + carryTotal;
  final daysLeftCycle =
      cycleNow.endExclusive.difference(Dates.dayKey(now)).inDays;
  var ccMonthly = 0;
  for (final c in cards) {
    ccMonthly += monthlyInstallmentDsrTotal(ref
            .watch(cardInstallmentsProvider((hid: household.id, cardId: c.id)))
            .value ??
        const []);
  }
  final stableGaji = ref.watch(stableSalaryProvider).value ?? 0;
  final debtSummary = debtServiceSummary(
    stableSalary: stableGaji,
    fixedObligationsMonthly: debtMonthly,
    multiMonthCardMonthly: ccMonthly,
    nonDebtMonthly: nonDebtMonthly,
  );
  final overcommit = budgetOvercommit(
    monthlyBudgetTotal: household.monthlyBudgetTotal,
    disposable: debtSummary.disposable,
  );

  // Budget dibatasi uang siap pakai: kalau budget yang diketik lebih
  // besar dari gaji − cicilan, sisanya tidak nyata untuk dibelanjakan.
  final hasCommitments =
      debtSummary.totalMonthlyDebt > 0 || nonDebtMonthly > 0;
  final effectiveBudget = hasCommitments && stableGaji > 0
      ? (household.monthlyBudgetTotal < debtSummary.disposable
              ? household.monthlyBudgetTotal
              : debtSummary.disposable) +
          carryTotal
      : budgetTotal;
  final sts = safeToSpend(
    totalBudget: effectiveBudget,
    spent: totalSpentValue,
    daysLeft: daysLeftCycle,
  );
  final safe = (
    perDay: sts.perDay,
    remaining: sts.remaining,
    daysLeft: daysLeftCycle,
    nextPayday: cycleNow.endExclusive,
    hasBudget: household.monthlyBudgetTotal > 0,
  );

  // One compact "Perlu perhatian" card instead of a stack of banners
  // — only things you can act on (due dates, the DSR/budget
  // warning). Nothing shown when there's nothing to act on.
  final attentionItems = [
    ...dueItems,
    if (debtSummary.dsr > dsrMaxOjk)
      AttentionItem(
        icon: Icons.warning_amber_rounded,
        color: FtColors.danger,
        text: 'Cicilan ${compactMoney(debtSummary.totalMonthlyDebt)} per bulan sudah '
            '${(debtSummary.dsr * 100).round()}% dari gaji, di atas batas aman OJK 30%',
        onTap: () => context.push('/obligations'),
      )
    else if (overcommit > 0 && hasCommitments)
      AttentionItem(
        icon: Icons.warning_amber_rounded,
        color: FtColors.ochre,
        text: 'Budget ${compactMoney(household.monthlyBudgetTotal)} lebih besar dari uang '
            'siap pakai ${compactMoney(debtSummary.disposable)}, yaitu gaji dikurangi cicilan',
        onTap: () => context.push('/spend'),
      ),
  ];

  return (
    expenses: expenses,
    categories: categories,
    byCat: byCat,
    carries: carries,
    goals: goals,
    nw: nw,
    trend: trend,
    trendDates: trendDates,
    cycleNet: cycleNet,
    totalSpentValue: totalSpentValue,
    gajiIncome: gajiIncome,
    health: health,
    safe: safe,
    insightCandidate: insightCandidate,
    attentionItems: attentionItems,
  );
}
