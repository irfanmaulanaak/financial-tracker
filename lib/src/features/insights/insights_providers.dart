import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/payday.dart';
import '../expenses/expense.dart';
import '../expenses/expense_repository.dart';
import '../household/household.dart';
import '../household/household_providers.dart';

// Re-exports so existing insights callers keep working.
export '../incomes/income_providers.dart' show currentCycleIncomeTotalProvider;

/// Expenses for the previous N budget cycles (excluding current).
final previousCyclesExpensesProvider =
    StreamProvider.family<List<List<Expense>>, int>((ref, cycles) async* {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) {
    yield const [];
    return;
  }
  // Build the bounds of the last `cycles` historical windows.
  final cycle = currentCycle(DateTime.now(), payday: household.payday);
  final windows = <({DateTime start, DateTime endExclusive})>[];
  var ref0 = cycle.start;
  for (var i = 0; i < cycles; i++) {
    final prevStart =
        resolvePayday(ref0.year, ref0.month - 1, household.payday);
    windows.add((start: prevStart, endExclusive: ref0));
    ref0 = prevStart;
  }
  // Stream the earliest start through the latest end and bucket client-side.
  final earliest = windows.last.start;
  yield* ref
      .watch(expenseRepositoryProvider)
      .watchInRange(
        householdId: household.id,
        startInclusive: earliest,
        endExclusive: cycle.start,
      )
      .map((all) {
    final out = <List<Expense>>[];
    for (final w in windows) {
      out.add(all
          .where((e) =>
              !e.date.isBefore(w.start) && e.date.isBefore(w.endExclusive))
          .toList());
    }
    return out;
  });
});

/// Pengeluaran kategori ZISWAF sejak 1 Januari tahun berjalan — untuk rekap
/// total tahunan (bantu hitung zakat/sedekah). Stream kosong bila tidak ada
/// kategori bertanda ZISWAF.
final ziswafYearExpensesProvider = StreamProvider<List<Expense>>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null || household.ziswafCategoryIds.isEmpty) {
    return Stream.value(const []);
  }
  final ids = household.ziswafCategoryIds;
  final now = DateTime.now();
  return ref
      .watch(expenseRepositoryProvider)
      .watchInRange(
        householdId: household.id,
        startInclusive: DateTime(now.year, 1, 1),
        endExclusive: now.add(const Duration(days: 1)),
      )
      .map((all) => [
            for (final e in all)
              if (ids.contains(e.categoryId)) e,
          ]);
});

/// Convenience: pulls the household's savings balance + card debt totals.
/// Callers pass `CreditCard.outstanding` as `used` so the debt figure is the
/// true remaining obligation (stable across statement dates).
({int savingsBalance, int cardDebt}) householdAssetsAndDebt(
  Household household,
  Iterable<({int limit, int used})> cards,
) {
  final savings =
      household.savingsAccounts.fold<int>(0, (a, b) => a + b.value);
  final debt = cards.fold<int>(0, (a, b) => a + b.used);
  return (savingsBalance: savings, cardDebt: debt);
}
