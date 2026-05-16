import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/payday.dart';
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
