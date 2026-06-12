/// Client-side recurring-transaction materialisation. Keeps things simple:
/// when the app opens, we look at the most recent recorded instance of each
/// recurring template (an expense or income with `recurring: true`) and, for
/// every full calendar month that has passed since, emit a new instance dated
/// on the same day-of-month (clamped to the month's last day).
///
/// This avoids the Cloud-Functions detour PLAN.md mentioned. Trade-off: if no
/// member opens the app for a month, materialisation lags. Acceptable for
/// 2-5 internal users.
library;

/// Materialisation plan: for each template, the list of new dates to create.
List<DateTime> datesToMaterialise({
  required DateTime lastSeen,
  required DateTime now,
}) {
  if (!now.isAfter(lastSeen)) return const [];
  final out = <DateTime>[];
  var cursor = _addMonthClampDay(lastSeen, 1);
  while (!cursor.isAfter(now)) {
    out.add(cursor);
    cursor = _addMonthClampDay(cursor, 1);
  }
  return out;
}

/// Picks the most-recent instance per template-key. `keyOf` reduces an
/// instance to its stable identity (category+amount+note, etc.).
Map<String, DateTime> latestPerKey<E>(
  Iterable<E> instances, {
  required String Function(E) keyOf,
  required DateTime Function(E) dateOf,
  required bool Function(E) isRecurring,
}) {
  final out = <String, DateTime>{};
  for (final e in instances) {
    if (!isRecurring(e)) continue;
    final k = keyOf(e);
    final d = dateOf(e);
    final existing = out[k];
    if (existing == null || d.isAfter(existing)) {
      out[k] = d;
    }
  }
  return out;
}

/// Next monthly occurrence after [lastSeen] (same day-of-month, clamped to
/// shorter months). Used by the subscriptions screen + local reminders.
DateTime nextMonthlyOccurrence(DateTime lastSeen) =>
    _addMonthClampDay(lastSeen, 1);

DateTime _addMonthClampDay(DateTime d, int months) {
  final targetMonth = d.month + months;
  final year = d.year + ((targetMonth - 1) ~/ 12);
  final month = ((targetMonth - 1) % 12) + 1;
  final lastDay = _daysInMonth(year, month);
  final day = d.day > lastDay ? lastDay : d.day;
  return DateTime(year, month, day, d.hour, d.minute);
}

int _daysInMonth(int year, int month) {
  final beginningNextMonth =
      (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return beginningNextMonth.subtract(const Duration(days: 1)).day;
}
