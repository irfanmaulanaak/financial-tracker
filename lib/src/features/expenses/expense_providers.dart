import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../../core/streak.dart';
import '../household/household_providers.dart';
import 'expense.dart';
import 'expense_repository.dart';

/// Expenses in the *current* budget cycle. Returns empty while household
/// isn't loaded.
final cycleExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);
  final cycle = currentCycle(DateTime.now(), payday: household.payday);
  return ref.watch(expenseRepositoryProvider).watchInRange(
        householdId: household.id,
        startInclusive: cycle.start,
        endExclusive: cycle.endExclusive,
      );
});

/// Recent N expenses (used by home dashboard).
final recentExpensesProvider =
    StreamProvider.family<List<Expense>, int>((ref, limit) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);
  return ref.watch(expenseRepositoryProvider).watchRecent(
        householdId: household.id,
        limit: limit,
      );
});

/// Recurring-flagged expenses of the last 12 months. Shared by the
/// "Langganan & Rutin" screen and the local-reminder scheduler.
final recurringExpensesYearProvider = StreamProvider<List<Expense>>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);
  return ref.watch(expenseRepositoryProvider).watchRecurringSince(
        householdId: household.id,
        since: DateTime.now().subtract(const Duration(days: 365)),
      );
});

/// Expenses of the last 60 days — source for the recording streak (a streak
/// can span cycle boundaries, so the cycle provider isn't enough).
final _last60DaysExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);
  final now = DateTime.now();
  return ref.watch(expenseRepositoryProvider).watchInRange(
        householdId: household.id,
        startInclusive: now.subtract(const Duration(days: 60)),
        endExclusive: now.add(const Duration(days: 1)),
      );
});

/// Current household recording streak (consecutive days with ≥1 expense).
final recordingStreakProvider = Provider<int>((ref) {
  final list = ref.watch(_last60DaysExpensesProvider).value ?? const [];
  return recordingStreak(
    daysWithEntries: {for (final e in list) Dates.dayKey(e.date)},
    today: DateTime.now(),
  );
});
