import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/payday.dart';
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
