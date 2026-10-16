import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../household/household_providers.dart';
import '../incomes/income.dart';
import '../incomes/income_repository.dart';

/// Incomes inside an arbitrary window (recap can look at past cycles, which
/// `cycleIncomesProvider` doesn't cover).
final windowIncomesProvider = StreamProvider.family<List<Income>,
    ({DateTime start, DateTime endExclusive})>((ref, w) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);
  return ref
      .watch(incomeRepositoryProvider)
      .watchRecent(hid: household.id, limit: 500)
      .map((items) => items
          .where((i) =>
              !i.date.isBefore(w.start) && i.date.isBefore(w.endExclusive))
          .toList());
});
