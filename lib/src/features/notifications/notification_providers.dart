import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/envelope.dart';
import '../../core/expense_aggregations.dart';
import '../../core/in_app_indicators.dart';
import '../../core/providers.dart';
import '../cards/cards_screen.dart' show cardsProvider;
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../goals/goal.dart' show Goal;
import '../goals/goals_screen.dart' show fundedGoalsProvider;
import '../household/household_providers.dart';
import '../insights/insights_providers.dart'
    show previousCyclesExpensesProvider;
import '../investments/investments_screen.dart' show investmentsProvider;

/// Notification kinds drive the icon + tone in the UI.
enum NotificationKind {
  overBudget,
  dueSoon,
  goalMilestone,
  memberSpend,
  investmentStale,
}

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
/// member spend activity, and stale-investment reminders.
///
/// Each notification carries a **stable** `ts` (tied to the underlying event
/// or condition) rather than `DateTime.now()` so the per-user "Bersihkan"
/// timestamp cutoff actually hides items until something new happens.
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
  // Stable ts per category = latest expense date in that category. Advances
  // when new spending lands, so a cleared notification re-surfaces only
  // after the next expense in that category.
  final latestExpenseByCat = <String, DateTime>{};
  for (final e in cycleExpenses) {
    final prev = latestExpenseByCat[e.categoryId];
    if (prev == null || e.date.isAfter(prev)) {
      latestExpenseByCat[e.categoryId] = e.date;
    }
  }
  // Rollover categories measure against budget + last cycle's leftover.
  final prevCycles =
      ref.watch(previousCyclesExpensesProvider(1)).value ??
          const <List<Expense>>[];
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
  for (final c in household.categories) {
    if (c.archived || c.monthlyBudget <= 0) continue;
    final spent = byCat[c.id] ?? 0;
    final limit = effectiveBudget(
      monthlyBudget: c.monthlyBudget,
      rollover: c.rollover,
      prevCycleSpent: prevByCat[c.id] ?? 0,
    );
    final status = budgetStatus(
      totalSpent: spent,
      monthlyBudget: limit,
    );
    if (status == BudgetStatus.exceeded) {
      out.add(AppNotification(
        id: 'overbudget-${c.id}',
        kind: NotificationKind.overBudget,
        group: NotificationGroup.fresh,
        title: '${c.label} melebihi anggaran',
        detail:
            'Sudah Rp ${_short(spent)} dari batas Rp ${_short(limit)}',
        ts: latestExpenseByCat[c.id] ?? now,
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
    // Stable ts = the actual due date for this cycle, so "Bersihkan" hides
    // it until next month's cycle (different due date → different ts).
    final dueTs = _resolveDueDate(dueDay: c.dueDay, now: now);
    out.add(AppNotification(
      id: 'due-${c.id}',
      kind: NotificationKind.dueSoon,
      group: NotificationGroup.fresh,
      title: '${c.label} jatuh tempo',
      detail: daysLeft <= 0
          ? 'Hari ini · Rp ${_short(c.used)}'
          : '$daysLeft hari lagi · Rp ${_short(c.used)}',
      ts: dueTs,
      route: '/cards',
    ));
  }

  // Goal milestones (≥75% / ≥100%) -----------------------------------------
  final goalsAsync = ref.watch(fundedGoalsProvider(household.id));
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

  // Stale investments (≥7 days since "nilai sekarang" update) --------------
  final investments = ref.watch(investmentsProvider(household.id)).value ??
      const [];
  for (final inv in investments) {
    if (!isInvestmentStale(
      updatedAt: inv.updatedAt,
      now: now,
      currentValue: inv.currentValue,
    )) {
      continue;
    }
    final daysAgo = now.difference(inv.updatedAt).inDays;
    out.add(AppNotification(
      id: 'inv-stale-${inv.id}',
      kind: NotificationKind.investmentStale,
      group: NotificationGroup.thisWeek,
      title: '${inv.label} belum diperbarui',
      detail: '${daysAgo}h sejak update nilai sekarang',
      // Stable ts = the moment this investment crossed the staleness
      // threshold (updatedAt + 7d). Advances only when the user updates,
      // so "Bersihkan" works correctly.
      ts: inv.updatedAt.add(const Duration(days: 7)),
      route: '/investments',
    ));
  }

  // Per-user clear-all cutoff. Hide everything older than the user's
  // `notificationsClearedAt` so new events still surface but old ones stay
  // dismissed.
  final userDoc = ref.watch(currentUserDocProvider).value;
  final clearedAtRaw = userDoc?['notificationsClearedAt'];
  final DateTime? clearedAt = clearedAtRaw is Timestamp
      ? clearedAtRaw.toDate()
      : (clearedAtRaw is DateTime ? clearedAtRaw : null);
  final filtered = clearedAt == null
      ? out
      : out.where((n) => n.ts.isAfter(clearedAt)).toList();

  // Sort newest first within each group order is preserved by ts desc.
  filtered.sort((a, b) => b.ts.compareTo(a.ts));
  return filtered;
});

/// Per-user "Bersihkan semua" — writes `notificationsClearedAt` on the user
/// doc so [notificationsProvider] hides everything older.
final clearNotificationsProvider =
    Provider<Future<void> Function()>((ref) {
  return () async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final db = ref.read(firestoreProvider);
    await db.collection('users').doc(user.uid).set(
      {'notificationsClearedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  };
});

/// Resolves the actual due date for the current cycle. Mirrors the rollover
/// behaviour in [daysUntilDue] so the two stay in sync.
DateTime _resolveDueDate({required int dueDay, required DateTime now}) {
  final today = DateTime(now.year, now.month, now.day);
  final lastInMonth =
      DateTime(now.year, now.month + 1, 0).day; // last day of this month
  final dom = dueDay > lastInMonth ? lastInMonth : dueDay;
  var due = DateTime(now.year, now.month, dom);
  if (due.isBefore(today)) {
    final ny = now.month == 12 ? now.year + 1 : now.year;
    final nm = now.month == 12 ? 1 : now.month + 1;
    final lastNext = DateTime(ny, nm + 1, 0).day;
    final domNext = dueDay > lastNext ? lastNext : dueDay;
    due = DateTime(ny, nm, domNext);
  }
  return due;
}

String _short(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} jt';
  if (v >= 1000) return '${(v / 1000).round()} rb';
  return v.toString();
}
