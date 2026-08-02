import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cash_projection.dart';
import '../../core/payday.dart';
import '../../core/recurring.dart';
import '../../core/recurring_runner.dart';
import '../../core/reminder_times.dart';
import '../../core/upcoming.dart';
import '../cards/cards_screen.dart' show cardsProvider;
import '../cards/credit_card.dart';
import '../expenses/expense.dart';
import '../expenses/expense_providers.dart';
import '../expenses/expense_repository.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../obligations/obligation_repository.dart';

// Re-exports so existing insights callers keep working.
export '../incomes/income_providers.dart' show currentCycleIncomeTotalProvider;

/// Tagihan terjadwal sisa siklus + proyeksi sisa kas — satu sumber untuk
/// Kalender Tagihan dan baris komitmen di hero home, supaya angkanya
/// tidak pernah beda antar layar.
final cycleBillsProvider =
    Provider<({List<UpcomingItem> items, CashProjection projection})?>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final cycle = currentCycle(now, payday: household.payday);
  final daysLeft = cycle.endExclusive.difference(today).inDays;
  final daysElapsed = today.difference(cycle.start).inDays + 1;

  final cards =
      ref.watch(cardsProvider(household.id)).value ?? const <CreditCard>[];
  final recurring =
      ref.watch(recurringExpensesYearProvider).value ?? const <Expense>[];
  final latest = latestPerKey<Expense>(
    recurring,
    keyOf: expenseTemplateKey,
    dateOf: (e) => e.date,
    isRecurring: (e) => e.recurring,
  );
  final items = upcomingItems(
    cards: [
      for (final c in cards) (label: c.label, dueDay: c.dueDay, used: c.used),
    ],
    bills: [
      for (final e in recurring)
        if (latest[expenseTemplateKey(e)] == e.date)
          (
            title: (e.note?.isNotEmpty ?? false)
                ? e.note!
                : (household.categoryOf(e.categoryId)?.label ?? 'Tagihan'),
            nextDate: nextMonthlyOccurrence(e.date),
            amount: e.amount,
          ),
      for (final o in ref.watch(obligationsProvider).value ?? const [])
        if (!o.isComplete && !o.paidForMonth(nextCardDueDate(o.dueDay, now)))
          (
            title: o.label,
            nextDate: nextCardDueDate(o.dueDay, now),
            amount: o.monthly,
          ),
    ],
    now: now,
    // Termasuk hari gajian berikutnya: tagihan yang jatuh tempo hari itu
    // tetap harus siap dari kas yang ada (gaji bisa masuk belakangan).
    withinDays: daysLeft,
  );

  final liquid = [
    ...household.cashAccounts,
    ...household.savingsAccounts.where((a) => a.liquid),
  ].fold<int>(0, (a, acc) => a + acc.value);
  final expenses = ref.watch(cycleExpensesProvider).value ?? const <Expense>[];
  final variableSpent = expenses
      .where((e) => !e.recurring && e.cardId == null)
      .fold<int>(0, (a, e) => a + e.amount);
  final projection = projectEndOfCycle(
    liquidNow: liquid,
    upcomingBillsTotal: items.fold(0, (a, i) => a + i.amount),
    variableSpentSoFar: variableSpent,
    daysElapsed: daysElapsed,
    daysLeft: daysLeft,
  );
  return (items: items, projection: projection);
});

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
