import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/expense_aggregations.dart';
import '../../core/health_score.dart';
import '../../core/home_layout_provider.dart';
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
import 'widgets/home_b_body.dart';
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

          Widget section(Widget child, {int index = 0}) => FtFadeUp(
                duration: const Duration(milliseconds: 340),
                delay: Duration(milliseconds: index * 60),
                distance: 10,
                child: child,
              );

          final displayName = prettyName(
              user?.displayName ?? user?.email ?? 'Keluarga');
          final layout = ref.watch(homeLayoutProvider);

          if (layout == 'B') {
            return FtAppChrome(
              current: FtTab.home,
              child: HomeBBody(
                household: household,
                displayName: displayName,
                nw: nw,
                totalSpent: totalSpentValue,
                income: income,
                health: health,
                cards: cards,
                goals: goals,
                categories: categories,
                totalsByCat: byCat,
                onMembers: () => context.push('/members'),
                onMenuSelect: _handleMenu,
                onAssets: () => context.push('/accounts'),
                onExpenses: () => context.push('/expenses'),
                onCards: () => context.push('/cards'),
                onGoals: () => context.push('/goals'),
                onInsights: () => context.push('/insights'),
              ),
            );
          }

          return FtAppChrome(
            current: FtTab.home,
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
                  AssetHeroCard(
                    nw: nw,
                    cycleNet: income - totalSpentValue,
                    onTap: () => context.push('/accounts'),
                  ),
                  index: 1,
                ),
                if (status != BudgetStatus.ok)
                  section(BudgetBanner(status: status), index: 2),
                for (var i = 0; i < dueBanners.length; i++)
                  section(dueBanners[i], index: 3 + i),
                section(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 13,
                            child: MonthStrip(
                              totalSpent: totalSpentValue,
                              income: income,
                              daily: daily,
                              todaySpend: expenses
                                  .where((e) =>
                                      e.date.year == now.year &&
                                      e.date.month == now.month &&
                                      e.date.day == now.day)
                                  .fold<int>(0, (a, e) => a + e.amount),
                              cycleStart: cycle.start,
                              cycleEndExclusive: cycle.endExclusive,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 10,
                            child: HealthSnapshot(
                              score: health,
                              onTap: () => context.push('/insights'),
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  index: 4,
                ),
                section(
                  CategoryGrid(
                    categories: categories.take(4).toList(),
                    totals: byCat,
                    onTap: () => context.push('/spend'),
                  ),
                  index: 5,
                ),
                section(
                  CardsPreview(
                    cards: cards,
                    onTap: () => context.push('/cards'),
                  ),
                  index: 6,
                ),
                section(
                  GoalsPreview(
                    goals: goals,
                    onTap: () => context.push('/goals'),
                  ),
                  index: 7,
                ),
                section(
                  RecentList(
                    recentAsync: recentAsync,
                    household: household,
                    onTap: () => context.push('/expenses'),
                  ),
                  index: 8,
                ),
              ],
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
      case 'settings':
        context.push('/settings');
      case 'signout':
        ref.read(authRepositoryProvider).signOut();
    }
  }
}
