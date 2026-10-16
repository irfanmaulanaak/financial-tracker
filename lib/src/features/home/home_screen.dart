import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/hide_assets_provider.dart';
import '../../core/layout_provider.dart';
import '../../core/providers.dart';
import '../../core/recurring_runner.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../auth/auth_repository.dart';
import '../cards/cards_screen.dart';
import '../household/household.dart';
import '../household/name_format.dart';
import '../expenses/expense_providers.dart';
import '../goals/goals_screen.dart';
import '../household/household_providers.dart';
import '../incomes/income_providers.dart';
import '../insights/insights_providers.dart';
import '../investments/investments_repository.dart' show investmentsProvider;
import '../notifications/reminder_scheduler.dart';
import '../onboarding/onboarding_state.dart';
import '../onboarding/widgets/onboarding_checklist.dart';
import '../onboarding/widgets/welcome_sheet.dart';
import 'home_screen_data.dart';
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
    // "Beranda" setting: Lengkap (default, everything) or Ringkas (only
    // safe-to-spend + this cycle's spending + banners that need action).
    final ringkas = ref.watch(homeLayoutProvider) == FtHomeLayout.ringkas;
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

          final user = ref.watch(authStateProvider).value;
          final data = buildHomeViewData(
            ref: ref,
            context: context,
            household: household,
            cycleAsync: cycleAsync,
          );
          final expenses = data.expenses;
          final categories = data.categories;
          final byCat = data.byCat;
          final carries = data.carries;
          final goals = data.goals;

          Widget section(Widget child, {int index = 0}) => FtFadeUp(
                duration: const Duration(milliseconds: 340),
                delay: Duration(milliseconds: index * 60),
                distance: 10,
                child: child,
              );

          final displayName = prettyName(
              user?.displayName ?? user?.email ?? 'Keluarga');

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
                padding: const EdgeInsets.only(bottom: kFtFabClearance),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [
                  section(
                    HomeHeader(
                      household: household,
                      displayName: displayName,
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
                      nw: data.nw,
                      trend: data.trend,
                      trendDates: data.trendDates,
                      cycleNet: data.cycleNet,
                      spend: data.totalSpentValue,
                      gajiIncome: data.gajiIncome,
                      health: data.health,
                      safe: data.safe,
                      compact: ringkas,
                    ),
                    index: 1,
                  ),
                  if (!ringkas)
                    section(
                      CommitmentLine(hidden: ref.watch(hideAssetsProvider)),
                      index: 1,
                    ),
                  if (data.attentionItems.isNotEmpty)
                    section(
                      AttentionCard(items: data.attentionItems),
                      index: 2,
                    ),
                  if (!ringkas)
                    section(
                      DailyInsightLine(candidate: data.insightCandidate),
                      index: 3,
                    ),
                  if (!ringkas)
                    section(
                      CategoryGrid(
                        categories: categories.take(4).toList(),
                        totals: byCat,
                        carries: carries,
                        onTap: () => context.push('/spend'),
                      ),
                      index: 3,
                    ),
                  if (!ringkas)
                    section(
                      GoalsPreview(
                        goals: goals,
                        onTap: () => context.push('/goals'),
                      ),
                      index: 4,
                    ),
                  if (!ringkas)
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
      case 'obligations':
        context.push('/obligations');
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
