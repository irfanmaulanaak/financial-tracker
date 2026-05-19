import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/expense_aggregations.dart';
import '../../core/health_score.dart';
import '../../core/in_app_indicators.dart';
import '../../core/net_worth.dart';
import '../../core/providers.dart';
import '../../core/recurring_runner.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../auth/auth_repository.dart';
import '../cards/credit_card.dart';
import '../cards/cards_screen.dart';
import '../household/name_format.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../goals/auto_debit_runner.dart';
import '../goals/goal.dart';
import '../goals/goals_screen.dart';
import '../household/household_providers.dart';
import '../incomes/income.dart';
import '../incomes/income_providers.dart';
import '../insights/insights_providers.dart';
import '../investments/investment.dart';
import '../investments/investments_screen.dart';
import 'net_worth_snapshot.dart';
import 'net_worth_snapshot_repository.dart';
import 'widgets/banners.dart';
import 'widgets/category_grid.dart';
import 'widgets/goals_preview.dart';
import 'widgets/home_header.dart';
import 'widgets/home_hero_carousel.dart';
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
    // Self-heal stale `users/{uid}.householdId` after a creator removed us
    // from the household.
    ref.watch(orphanedMembershipCleanupProvider);
    final loadedHid = householdAsync.value?.id;
    if (loadedHid != null && loadedHid != _lastRecurringHid) {
      _lastRecurringHid = loadedHid;
      // Fire-and-forget; failures are non-fatal (next session retries).
      // ignore: discarded_futures
      ref.read(recurringRunnerProvider).run(householdId: loadedHid);
      // ignore: discarded_futures
      ref.read(autoDebitRunnerProvider).run(householdId: loadedHid);
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

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: householdAsync.when(
        loading: () => const FtSkeletonListView(count: 5, tileHeight: 90),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (household) {
          if (household == null) {
            return const Center(child: Text('Tidak ada rumah tangga.'));
          }

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
          final totalSpentValue = totalSpent(records);
          final income = ref.watch(currentCycleIncomeTotalProvider);
          final gajiIncome = (ref.watch(cycleIncomesProvider).value ??
                  const <Income>[])
              .where((i) => i.source == IncomeSource.salary)
              .fold<int>(0, (a, b) => a + b.amount);
          final byCat = spentByCategory(records);
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
          final prevAsync = ref.watch(previousCyclesExpensesProvider(3));
          final prevCycles = prevAsync.value ?? const <List<Expense>>[];
          final avgPrev = prevCycles.isEmpty
              ? 0
              : prevCycles
                        .map((w) => w.fold<int>(0, (a, b) => a + b.amount))
                        .fold<int>(0, (a, b) => a + b) ~/
                    prevCycles.length;
          final invTotal =
              investments.fold<int>(0, (a, i) => a + i.currentValue);
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
            investments: invTotal,
          );
          final assets = householdAssetsAndDebt(
            household,
            cards.map((c) => (limit: c.limit, used: c.used)),
          );
          // Record today's net-worth snapshot once everything's loaded.
          // Idempotent per day (see [NetWorthSnapshotRepository.recordToday]).
          if (user != null &&
              cardsAsync?.hasValue == true &&
              investmentsAsync?.hasValue == true) {
            // ignore: discarded_futures
            ref
                .read(netWorthSnapshotRepositoryProvider)
                .recordToday(
                  householdId: household.id,
                  nw: nw,
                  capturedBy: user.uid,
                );
          }
          final history =
              ref.watch(netWorthHistoryProvider(14)).value ?? const <NetWorthSnapshot>[];
          final trend = [for (final s in history) s.total.toDouble()];
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
          final dueBanners = [
            for (final c in cards)
              if (daysUntilDue(dueDay: c.dueDay, now: now) case final d?)
                if (c.used > 0)
                  DueBanner(cardLabel: c.label, daysUntil: d, used: c.used),
          ];

          Widget section(Widget child, {int index = 0}) => FtFadeUp(
                duration: const Duration(milliseconds: 340),
                delay: Duration(milliseconds: index * 60),
                distance: 10,
                child: child,
              );

          final displayName = prettyName(
              user?.displayName ?? user?.email ?? 'Keluarga');

          // Cycle net used by the asset slide's delta pill. Use Gaji-only
          // income so it matches the ratio slide (and what the user really
          // means by "earnings this cycle").
          final cycleNet = gajiIncome - totalSpentValue;

          return FtAppChrome(
            current: FtTab.home,
            child: FtRefreshable(
              onRefresh: () async {
                ref.invalidate(currentHouseholdProvider);
                ref.invalidate(cycleExpensesProvider);
                ref.invalidate(cycleIncomesProvider);
                ref.invalidate(recentExpensesProvider(5));
                ref.invalidate(cardsProvider(household.id));
                ref.invalidate(goalsProvider(household.id));
                ref.invalidate(investmentsProvider(household.id));
                ref.invalidate(previousCyclesExpensesProvider);
                ref.invalidate(netWorthHistoryProvider);
                await ftRefreshDelay();
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  section(
                    HomeHeader(
                      household: household,
                      displayName: displayName,
                      onMembers: () => context.push('/members'),
                      onSelected: _handleMenu,
                    ),
                    index: 0,
                  ),
                  section(
                    HomeHeroCarousel(
                      nw: nw,
                      trend: trend,
                      cycleNet: cycleNet,
                      spend: totalSpentValue,
                      gajiIncome: gajiIncome,
                      cards: cards,
                      health: health,
                    ),
                    index: 1,
                  ),
                  for (var i = 0; i < dueBanners.length; i++)
                    section(dueBanners[i], index: 2 + i),
                  section(
                    CategoryGrid(
                      categories: categories.take(4).toList(),
                      totals: byCat,
                      onTap: () => context.push('/spend'),
                    ),
                    index: 3,
                  ),
                  section(
                    GoalsPreview(
                      goals: goals,
                      onTap: () => context.push('/goals'),
                    ),
                    index: 4,
                  ),
                  section(
                    RecentList(
                      recentAsync: recentAsync,
                      household: household,
                      onTap: () => context.push('/expenses'),
                    ),
                    index: 5,
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
        context.push('/health');
      case 'categories':
        context.push('/categories');
      case 'members':
        context.push('/members');
      case 'export':
        context.push('/export');
      case 'settings':
        context.push('/settings');
      case 'signout':
        ref.read(authRepositoryProvider).signOut();
    }
  }
}
