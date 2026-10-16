import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
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
import 'widgets/activity_section.dart';
import 'widgets/banners.dart';
import 'widgets/home_extras.dart';
import 'widgets/home_header.dart';
import 'widgets/home_hero_scene.dart';

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
    // "Beranda" setting: Lengkap (default, everything) or Ringkas (only the
    // hero + what needs attention).
    final ringkas = ref.watch(homeLayoutProvider) == FtHomeLayout.ringkas;
    final householdAsync = ref.watch(currentHouseholdProvider);
    // Self-heal stale `users/{uid}.householdId` after a creator removed us.
    ref.watch(orphanedMembershipCleanupProvider);
    // Keep local reminders in sync with settings + cards + recurring bills.
    ref.watch(reminderSchedulerProvider);
    final loadedHid = householdAsync.value?.id;
    if (loadedHid != null && loadedHid != _lastRecurringHid) {
      _lastRecurringHid = loadedHid;
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
          final displayName =
              prettyName(user?.displayName ?? user?.email ?? 'Keluarga');
          final onbActive = ref.watch(onboardingProvider).checklistActive;
          const gap = SizedBox(height: 28);

          final body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero color runs from the very top (incl. the status-bar area)
              // through the header into the hill — no seam against the panel.
              ColoredBox(
                color: FtColors.hero,
                child: HomeHeader(
                  household: household,
                  displayName: displayName,
                  onSelected: _handleMenu,
                ),
              ),
              HomeHeroScene(
                perDay: data.safe.perDay,
                remaining: data.safe.remaining,
                daysLeft: data.safe.daysLeft,
                hasBudget: data.safe.hasBudget,
                mood: data.mood,
                daysElapsed: data.daysElapsed,
                cycleLength: data.cycleLength,
                insightCandidate: data.insightCandidate,
                startLabel: Dates.dayMonth(data.cycleStart),
                paydayLabel: 'Gajian ${Dates.dayMonth(data.safe.nextPayday)}',
                inputsReady: data.heroInputsReady,
                showNetWorth: !ringkas,
                nwTotal: data.nw.total,
                // Live top minus the first value of the 14-day series (not
                // trend.last, which the day's snapshot write would move right
                // after the hero settles). Null when there's no history.
                nwChangeFrom:
                    data.trend.length >= 2 ? data.trend.first : null,
              ),
              if (onbActive) ...[
                gap,
                OnboardingChecklist(
                  household: household,
                  hasExpense: data.expenses.isNotEmpty ||
                      (recentAsync.value?.isNotEmpty ?? false),
                ),
              ],
              if (data.attentionItems.isNotEmpty) ...[
                gap,
                AttentionSection(items: data.attentionItems),
              ],
              if (!ringkas) ...[
                gap,
                ActivitySection(
                    recentAsync: recentAsync, household: household),
                if (data.categories.isNotEmpty) ...[
                  gap,
                  BudgetSection(
                    categories: data.categories,
                    totals: data.byCat,
                    carries: data.carries,
                  ),
                ],
                if (data.goals.isNotEmpty) ...[
                  gap,
                  GoalsSection(goals: data.goals),
                ],
              ],
              const SizedBox(height: 8),
            ],
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
                padding: const EdgeInsets.only(bottom: kFtFabClearance),
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                children: [body],
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
