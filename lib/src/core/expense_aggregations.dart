import 'formatters.dart';

/// Pure aggregation helpers for expenses. Designed to be testable without
/// touching Firestore — caller passes already-fetched expense records.
class ExpenseRecord {
  final num amount;
  final String categoryId;
  final String spentBy;
  final DateTime date;

  const ExpenseRecord({
    required this.amount,
    required this.categoryId,
    required this.spentBy,
    required this.date,
  });
}

/// Sum of all expenses.
int totalSpent(Iterable<ExpenseRecord> expenses) =>
    expenses.fold<int>(0, (a, e) => a + e.amount.toInt());

/// Drops expenses whose category is an investment category. Spend totals
/// count consumption only — buying an instrument is saving, not spending —
/// but the dropped records stay visible in activity lists.
List<ExpenseRecord> consumptionOnly(
  Iterable<ExpenseRecord> expenses,
  Set<String> investmentCategoryIds,
) =>
    [
      for (final e in expenses)
        if (!investmentCategoryIds.contains(e.categoryId)) e,
    ];

/// Spend grouped by `categoryId`. Categories with zero spend are omitted.
Map<String, int> spentByCategory(Iterable<ExpenseRecord> expenses) {
  final out = <String, int>{};
  for (final e in expenses) {
    out.update(e.categoryId, (v) => v + e.amount.toInt(),
        ifAbsent: () => e.amount.toInt());
  }
  return out;
}

/// Spend grouped by spender uid.
Map<String, int> spentByMember(Iterable<ExpenseRecord> expenses) {
  final out = <String, int>{};
  for (final e in expenses) {
    out.update(e.spentBy, (v) => v + e.amount.toInt(),
        ifAbsent: () => e.amount.toInt());
  }
  return out;
}

/// Groups expenses by local day, newest first. Within a day, original order
/// is preserved (caller is expected to sort the source by date desc).
Map<DateTime, List<ExpenseRecord>> groupByDay(Iterable<ExpenseRecord> expenses) {
  final out = <DateTime, List<ExpenseRecord>>{};
  for (final e in expenses) {
    final key = Dates.dayKey(e.date);
    out.putIfAbsent(key, () => []).add(e);
  }
  return out;
}

/// Returns the top-N category IDs by spend, descending.
List<MapEntry<String, int>> topCategories(
  Iterable<ExpenseRecord> expenses, {
  int limit = 3,
}) {
  final byCat = spentByCategory(expenses).entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return byCat.take(limit).toList();
}

/// Daily budget = monthly budget / days in cycle.
int dailyBudget({required int monthlyBudget, required int cycleDays}) {
  if (cycleDays <= 0) return 0;
  return (monthlyBudget / cycleDays).round();
}
