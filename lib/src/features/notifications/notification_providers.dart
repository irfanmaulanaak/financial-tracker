import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/expense_aggregations.dart';
import '../../core/in_app_indicators.dart';
import '../../core/providers.dart';
import '../cards/cards_screen.dart' show cardsProvider;
import '../expenses/expense_providers.dart';
import '../goals/goal.dart' show Goal;
import '../goals/goals_screen.dart' show goalsProvider;
import '../household/household_providers.dart';

/// Notification kinds drive the icon + tone in the UI.
enum NotificationKind { overBudget, dueSoon, goalMilestone, memberSpend }

/// Group buckets shown on the screen.
enum NotificationGroup { fresh, thisWeek }

class AppNotification {
  final String id;
  final NotificationKind kind;
  final NotificationGroup group;
  final String title;
  final String detail;
  final DateTime ts;
  final String? route;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.group,
    required this.title,
    required this.detail,
    required this.ts,
    this.route,
  });
}

/// Derives a notification feed from existing providers. No new Firestore
/// collection — surfaces budget over-warnings, CC dues ≤5d, goal milestones,
/// and member spend activity.
final notificationsProvider = Provider<List<AppNotification>>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return const [];
  final now = DateTime.now();
  final fresh = now.subtract(const Duration(hours: 24));
  final thisWeekCutoff = now.subtract(const Duration(days: 7));

  final out = <AppNotification>[];

  // Over-budget categories (current cycle) ----------------------------------
  final cycleExpenses = ref.watch(cycleExpensesProvider).value ?? const [];
  final byCat = spentByCategory([
    for (final e in cycleExpenses)
      ExpenseRecord(
        amount: e.amount,
        categoryId: e.categoryId,
        spentBy: e.spentBy,
        date: e.date,
      ),
  ]);
  for (final c in household.categories) {
    if (c.archived || c.monthlyBudget <= 0) continue;
    final spent = byCat[c.id] ?? 0;
    final status = budgetStatus(
      totalSpent: spent,
      monthlyBudget: c.monthlyBudget,
    );
    if (status == BudgetStatus.exceeded) {
      out.add(AppNotification(
        id: 'overbudget-${c.id}',
        kind: NotificationKind.overBudget,
        group: NotificationGroup.fresh,
        title: '${c.label} melebihi anggaran',
        detail:
            'Sudah Rp ${_short(spent)} dari batas Rp ${_short(c.monthlyBudget)}',
        ts: now,
        route: '/categories/${c.id}',
      ));
    }
  }

  // CC due ≤5 days ----------------------------------------------------------
  final cardsAsync = ref.watch(cardsProvider(household.id));
  final cards = cardsAsync.value ?? const [];
  for (final c in cards) {
    if (c.used <= 0) continue;
    final daysLeft = daysUntilDue(dueDay: c.dueDay, now: now);
    if (daysLeft == null) continue;
    out.add(AppNotification(
      id: 'due-${c.id}',
      kind: NotificationKind.dueSoon,
      group: NotificationGroup.fresh,
      title: '${c.label} jatuh tempo',
      detail: daysLeft <= 0
          ? 'Hari ini · Rp ${_short(c.used)}'
          : '$daysLeft hari lagi · Rp ${_short(c.used)}',
      ts: now,
      route: '/cards',
    ));
  }

  // Goal milestones (≥75% / ≥100%) -----------------------------------------
  final goalsAsync = ref.watch(goalsProvider(household.id));
  final goals = goalsAsync.value ?? const <Goal>[];
  for (final g in goals) {
    if (g.target <= 0) continue;
    final pct = (g.current / g.target).clamp(0.0, 1.0);
    if (pct >= 1.0) {
      out.add(AppNotification(
        id: 'goal-done-${g.id}',
        kind: NotificationKind.goalMilestone,
        group: NotificationGroup.thisWeek,
        title: '${g.label} · target tercapai',
        detail: 'Selamat! Tujuan tercapai.',
        ts: g.createdAt,
        route: '/goals/${g.id}',
      ));
    } else if (pct >= 0.75) {
      out.add(AppNotification(
        id: 'goal-75-${g.id}',
        kind: NotificationKind.goalMilestone,
        group: NotificationGroup.thisWeek,
        title: '${g.label} · ${(pct * 100).round()}% tercapai',
        detail: 'Sedikit lagi menuju Rp ${_short(g.target)}.',
        ts: g.createdAt,
        route: '/goals/${g.id}',
      ));
    }
  }

  // Recent member spend (last 7 days, excluding self) ----------------------
  final recent = ref.watch(recentExpensesProvider(20)).value ?? const [];
  final me =
      household.creatorId; // best-effort fallback, replaced below if user known
  final auth = ref.watch(authStateProvider).value;
  final selfId = auth?.uid ?? me;
  for (final e in recent.take(8)) {
    if (e.spentBy == selfId) continue;
    if (e.date.isBefore(thisWeekCutoff)) continue;
    final spender = household.memberOf(e.spentBy);
    final cat = household.categoryOf(e.categoryId);
    final inFresh = e.date.isAfter(fresh);
    out.add(AppNotification(
      id: 'spend-${e.id}',
      kind: NotificationKind.memberSpend,
      group: inFresh ? NotificationGroup.fresh : NotificationGroup.thisWeek,
      title: '${spender?.displayName ?? 'Anggota'} mencatat pengeluaran',
      detail:
          'Rp ${_short(e.amount)} · ${cat?.label ?? 'Lainnya'}${(e.note ?? '').isNotEmpty ? ' · ${e.note}' : ''}',
      ts: e.date,
      route: '/expenses',
    ));
  }

  // Sort newest first within each group order is preserved by ts desc.
  out.sort((a, b) => b.ts.compareTo(a.ts));
  return out;
});

String _short(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} jt';
  if (v >= 1000) return '${(v / 1000).round()} rb';
  return v.toString();
}
