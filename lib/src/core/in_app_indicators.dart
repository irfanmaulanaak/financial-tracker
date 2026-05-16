/// In-app banner indicators (no push notifications in MVP).
/// Pure logic so we can test thresholds deterministically.
library;

enum BudgetStatus { ok, warning, exceeded }

BudgetStatus budgetStatus({
  required int totalSpent,
  required int monthlyBudget,
}) {
  if (monthlyBudget <= 0) return BudgetStatus.ok;
  final ratio = totalSpent / monthlyBudget;
  if (ratio >= 1.0) return BudgetStatus.exceeded;
  if (ratio >= 0.8) return BudgetStatus.warning;
  return BudgetStatus.ok;
}

/// Returns null when not due soon. Otherwise returns the # of days until the
/// next due date (negative if already past).
int? daysUntilDue({
  required int dueDay,
  required DateTime now,
  int warnWithinDays = 5,
}) {
  final last = _lastDayOfMonth(now.year, now.month);
  final dom = dueDay > last ? last : dueDay;
  var due = DateTime(now.year, now.month, dom);
  if (due.isBefore(DateTime(now.year, now.month, now.day))) {
    // Roll to next month
    final nextMonth = now.month + 1;
    final ny = now.year + ((nextMonth - 1) ~/ 12);
    final nm = ((nextMonth - 1) % 12) + 1;
    final lastNext = _lastDayOfMonth(ny, nm);
    final domNext = dueDay > lastNext ? lastNext : dueDay;
    due = DateTime(ny, nm, domNext);
  }
  final diff = due.difference(DateTime(now.year, now.month, now.day)).inDays;
  if (diff > warnWithinDays) return null;
  return diff;
}

int _lastDayOfMonth(int year, int month) {
  final beginningNext =
      (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return beginningNext.subtract(const Duration(days: 1)).day;
}
