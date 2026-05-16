import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/expense_aggregations.dart';
import '../../core/health_score.dart';
import '../../core/in_app_indicators.dart';
import '../../core/net_worth.dart';
import '../../core/payday.dart';
import '../../core/providers.dart';
import '../../core/recurring_runner.dart';
import '../../theme.dart';
import '../../ui/ft_motion.dart';
import '../../ui/ft_ui.dart';
import '../auth/auth_repository.dart';
import '../cards/credit_card.dart';
import '../cards/cards_screen.dart';
import '../household/name_format.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../goals/goal.dart';
import '../goals/goals_screen.dart';
import '../household/household_providers.dart';
import '../insights/insights_providers.dart';
import '../investments/investment.dart';
import '../investments/investments_screen.dart';
import 'widgets/banners.dart';
import 'widgets/cards_preview.dart';
import 'widgets/category_grid.dart';
import 'widgets/goals_preview.dart';
import 'widgets/health_snapshot.dart';
import 'widgets/home_header.dart';
import 'widgets/month_strip.dart';
import 'widgets/net_worth_section.dart';
import 'widgets/recent_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _lastRecurringHid;

  @override
  Widget build(BuildContext context) {
    final householdAsync = ref.watch(currentHouseholdProvider);
    final loadedHid = householdAsync.value?.id;
    if (loadedHid != null && loadedHid != _lastRecurringHid) {
      _lastRecurringHid = loadedHid;
      // Fire-and-forget; failures are non-fatal (next session retries).
      // ignore: discarded_futures
      ref.read(recurringRunnerProvider).run(householdId: loadedHid);
    }
    final cycleAsync = ref.watch(cycleExpensesProvider);
    final recentAsync = ref.watch(recentExpensesProvider(5));
    final user = ref.watch(authStateProvider).value;
    final household = householdAsync.value;
    final cardsAsync = household != null
        ? ref.watch(cardsProvider(household.id))
        : null;
    final goalsAsync = household != null
        ? ref.watch(goalsProvider(household.id))
        : null;
    final investmentsAsync = household != null
        ? ref.watch(investmentsProvider(household.id))
        : null;
    final prevAsync = household != null
        ? ref.watch(previousCyclesExpensesProvider(3))
        : null;

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: householdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (household) {
          if (household == null) {
            return const Center(child: Text('Tidak ada rumah tangga.'));
          }

          final now = DateTime.now();
          final cycle = currentCycle(now, payday: household.payday);
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
          final totalSpentValue = totalSpent(records);
          final income = ref.watch(currentCycleIncomeTotalProvider);
          final byCat = spentByCategory(records);
          final daily = dailyBudget(
            monthlyBudget: income,
            cycleDays: cycleLengthDays(cycle),
          );
          final categories =
              household.categories.where((c) => !c.archived).toList()
                ..sort((a, b) {
                  final sa = byCat[a.id] ?? 0;
                  final sb = byCat[b.id] ?? 0;
                  if (sa != sb) return sb.compareTo(sa);
                  return a.sortOrder.compareTo(b.sortOrder);
                });

          final cards = cardsAsync?.value ?? const <CreditCard>[];
          final goals = goalsAsync?.value ?? const <Goal>[];
          final investments = investmentsAsync?.value ?? const <Investment>[];
          final prevCycles = prevAsync?.value ?? const <List<Expense>>[];
          final avgPrev = prevCycles.isEmpty
              ? 0
              : prevCycles
                        .map((w) => w.fold<int>(0, (a, b) => a + b.amount))
                        .fold<int>(0, (a, b) => a + b) ~/
                    prevCycles.length;
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
                  used: c.used,
                ),
            ],
          );
          final assets = householdAssetsAndDebt(
            household,
            cards.map((c) => (limit: c.limit, used: c.used)),
          );
          final health = computeHealthScore(
            HealthScoreInputs(
              spendThisCycle: totalSpentValue,
              incomeThisCycle: income,
              monthlyBudget: household.monthlyBudgetTotal,
              savingsBalance: assets.savingsBalance,
              cardDebt: assets.cardDebt,
              avgMonthlySpend: avgPrev,
              investmentCount: investments
                  .where((i) => i.currentValue > 0)
                  .length,
            ),
          );
          final status = budgetStatus(
            totalSpent: totalSpentValue,
            monthlyBudget: income,
          );
          final dueBanners = [
            for (final c in cards)
              if (daysUntilDue(dueDay: c.dueDay, now: now) case final d?)
                if (c.used > 0)
                  DueBanner(cardLabel: c.label, daysUntil: d, used: c.used),
          ];

          return FtAppChrome(
            current: FtTab.home,
            child: FtFadeUp(
              duration: const Duration(milliseconds: 360),
              distance: 10,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                HomeHeader(
                  household: household,
                  displayName: prettyName(
                      user?.displayName ?? user?.email ?? 'Keluarga'),
                  onMembers: () => context.push('/members'),
                  onSelected: _handleMenu,
                ),
                AssetHero(nw: nw, onTap: () => context.push('/accounts')),
                AssetBreakdown(nw: nw, onTap: () => context.push('/accounts')),
                if (status != BudgetStatus.ok) BudgetBanner(status: status),
                for (final banner in dueBanners) banner,
                MonthStrip(
                  totalSpent: totalSpentValue,
                  income: income,
                  daily: daily,
                  cycleStart: cycle.start,
                  cycleEndExclusive: cycle.endExclusive,
                ),
                CardsPreview(
                  cards: cards,
                  onTap: () => context.push('/cards'),
                ),
                HealthSnapshot(
                  score: health,
                  onTap: () => context.push('/insights'),
                ),
                CategoryGrid(
                  categories: categories.take(4).toList(),
                  totals: byCat,
                  onTap: () => context.push('/expenses'),
                ),
                GoalsPreview(
                  goals: goals,
                  onTap: () => context.push('/goals'),
                ),
                RecentList(
                  recentAsync: recentAsync,
                  household: household,
                  onTap: () => context.push('/expenses'),
                ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleMenu(String v) {
    switch (v) {
      case 'insights':
        context.push('/insights');
      case 'categories':
        context.push('/categories');
      case 'members':
        context.push('/members');
      case 'export':
        context.push('/export');
      case 'signout':
        ref.read(authRepositoryProvider).signOut();
    }
  }
}
