import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/payday.dart';
import '../../core/stable_income.dart';
import '../household/household_providers.dart';
import 'income.dart';
import 'income_repository.dart';

/// All income records in the current budget cycle, newest first.
/// (Empty when household not loaded yet.)
final cycleIncomesProvider = StreamProvider<List<Income>>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);
  final cycle = currentCycle(DateTime.now(), payday: household.payday);
  return ref
      .watch(incomeRepositoryProvider)
      .watchRecent(hid: household.id, limit: 200)
      .map((items) => items
          .where((i) =>
              !i.date.isBefore(cycle.start) &&
              i.date.isBefore(cycle.endExclusive))
          .toList());
});

/// Total IDR earned in the current cycle. Sums [cycleIncomesProvider].
final currentCycleIncomeTotalProvider = Provider<int>((ref) {
  final list = ref.watch(cycleIncomesProvider).value ?? const [];
  return list.fold<int>(0, (a, b) => a + b.amount);
});

/// Gaji stabil (`salary` saja); fallback gaji siklus berjalan bila belum
/// ada riwayat siklus lengkap.
final stableSalaryProvider = StreamProvider<int>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(0);
  return ref
      .watch(incomeRepositoryProvider)
      .watchRecent(hid: household.id, limit: 200)
      .map((items) {
    final salaries = items
        .where((i) => i.source == IncomeSource.salary)
        .map((i) => (date: i.date, amount: i.amount))
        .toList();
    final stable = stableSalary(
      salaryIncomes: salaries,
      now: DateTime.now(),
      payday: household.payday,
    );
    if (stable > 0) return stable;
    final cycle = currentCycle(DateTime.now(), payday: household.payday);
    return salaries
        .where((i) =>
            !i.date.isBefore(cycle.start) && i.date.isBefore(cycle.endExclusive))
        .fold<int>(0, (a, b) => a + b.amount);
  });
});
