import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/daily_insight.dart';
import '../../core/envelope.dart';
import '../../core/expense_aggregations.dart';
import '../../core/formatters.dart';
import '../../core/health_score.dart';
import '../../core/in_app_indicators.dart';
import '../../core/net_worth.dart';
import '../../core/payday.dart';
import '../../core/providers.dart';
import '../../core/recurring_runner.dart';
import '../../core/safe_to_spend.dart';
import '../../core/streak.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../auth/auth_repository.dart';
import '../cards/credit_card.dart';
import '../cards/cards_screen.dart';
import '../household/household.dart';
import '../household/name_format.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../goals/goal.dart';
import '../goals/goals_screen.dart';
import '../household/household_providers.dart';
import '../incomes/income.dart';
import '../incomes/income_providers.dart';
import '../insights/insights_providers.dart';
import '../investments/investment.dart';
import '../investments/investments_repository.dart' show investmentsProvider;
import '../notifications/reminder_scheduler.dart';
import '../onboarding/onboarding_state.dart';
import '../onboarding/widgets/onboarding_checklist.dart';
import '../onboarding/widgets/welcome_sheet.dart';
import 'net_worth_snapshot.dart';
import 'net_worth_snapshot_repository.dart';
import 'widgets/banners.dart';
import 'widgets/category_grid.dart';
import 'widgets/daily_insight_line.dart';
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
  bool _welcomeShown = false;

  /// Welcome sheet untuk anggota yang baru join — flag-nya hanya di-set
  /// oleh join screen, jadi user lama tidak pernah kena. Sekali tampil,
  /// langsung ditandai selesai.
  void _maybeShowWelcome(Household household) {
    if (_welcomeShown) return;
    if (!ref.read(onboardingProvider).welcomePending) return;
    final uid = ref.read(authStateProvider).value?.uid;
    final member = uid == null ? null : household.memberOf(uid);
    if (member == null) return;
    _welcomeShown = true;
    final canRecord = ref.read(canRecordTxnProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ignore: discarded_futures
      ref.read(onboardingProvider.notifier).markWelcomeSeen();
      // ignore: discarded_futures
      showOnboardingWelcomeSheet(
        context,
        household: household,
        member: member,
        canRecord: canRecord,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final householdAsync = ref.watch(currentHouseholdProvider);
    // Self-heal stale `users/{uid}.householdId` after a creator removed us
    // from the household.
    ref.watch(orphanedMembershipCleanupProvider);
    // Keep local reminders in sync with settings + cards + recurring bills.
    ref.watch(reminderSchedulerProvider);
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
        ? ref.watch(fundedGoalsProvider(household.id))
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
          _maybeShowWelcome(household);

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
          final totalSpentValue =
              totalSpent(consumptionOnly(records, invCatIds));
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
                  // Net worth counts the true obligation (full unpaid cicilan
                  // remainder), not the statement-day `used` figure — so the
                  // chart doesn't jump on tanggal cetak.
                  used: c.outstanding,
                ),
            ],
            investments: invTotal,
          );
          final assets = householdAssetsAndDebt(
            household,
            cards.map((c) => (limit: c.limit, used: c.outstanding)),
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
          final streak = ref.watch(recordingStreakProvider);

          // Insight 1 kalimat/hari — kandidat dihitung dari data terkini,
          // dikunci per-hari oleh DailyInsightLine.
          final cycleNow = currentCycle(now, payday: household.payday);
          final yesterdayKey = Dates.dayKey(now)
              .subtract(const Duration(days: 1));
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
            daysElapsed:
                Dates.dayKey(now).difference(cycleNow.start).inDays + 1,
            cycleLength: cycleLengthDays(cycleNow),
            noSpendYesterday: !cycleNow.start.isAfter(yesterdayKey) &&
                expenses.every((e) => Dates.dayKey(e.date) != yesterdayKey),
          );

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

          // Slide "aman dibelanjakan": budget total (termasuk carry amplop)
          // − terpakai, dibagi hari tersisa sampai gajian.
          final carryTotal =
              carries.values.fold<int>(0, (a, b) => a + b);
          final budgetTotal = household.monthlyBudgetTotal + carryTotal;
          final daysLeftCycle = cycleNow.endExclusive
              .difference(Dates.dayKey(now))
              .inDays;
          final sts = safeToSpend(
            totalBudget: budgetTotal,
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
                    OnboardingChecklist(
                      household: household,
                      hasExpense: expenses.isNotEmpty ||
                          (recentAsync.value?.isNotEmpty ?? false),
                    ),
                    index: 1,
                  ),
                  section(
                    HomeHeroCarousel(
                      nw: nw,
                      trend: trend,
                      trendDates: trendDates,
                      cycleNet: cycleNet,
                      spend: totalSpentValue,
                      gajiIncome: gajiIncome,
                      cards: cards,
                      health: health,
                      safe: safe,
                    ),
                    index: 1,
                  ),
                  for (var i = 0; i < dueBanners.length; i++)
                    section(dueBanners[i], index: 2 + i),
                  if (streak >= minVisibleStreak)
                    section(
                      StreakBanner(streak: streak),
                      index: 2 + dueBanners.length,
                    ),
                  section(
                    DailyInsightLine(candidate: insightCandidate),
                    index: 3,
                  ),
                  section(
                    CategoryGrid(
                      categories: categories.take(4).toList(),
                      totals: byCat,
                      carries: carries,
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
      case 'onboarding':
        // ignore: discarded_futures
        ref.read(onboardingProvider.notifier).reopenChecklist();
      case 'insights':
        context.push('/health');
      case 'recap':
        context.push('/recap');
      case 'categories':
        context.push('/categories');
      case 'subscriptions':
        context.push('/subscriptions');
      case 'calendar':
        context.push('/calendar');
      case 'debts':
        context.push('/debts');
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
