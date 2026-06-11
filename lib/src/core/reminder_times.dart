/// Pure date math for local reminders — unit-testable without the
/// notifications plugin.
library;

/// Next occurrence of HH:mm strictly after [now] (today if still ahead,
/// otherwise tomorrow).
DateTime nextTimeOfDay(DateTime now, int hour, int minute) {
  var candidate = DateTime(now.year, now.month, now.day, hour, minute);
  if (!candidate.isAfter(now)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}

/// Next credit-card due date on/after today. [dueDay] is clamped to each
/// month's length (due day 31 → 28/29 Feb), mirroring `daysUntilDue`.
DateTime nextCardDueDate(int dueDay, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime candidate(int year, int month) {
    final last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, dueDay > last ? last : dueDay);
  }

  final thisMonth = candidate(now.year, now.month);
  if (!thisMonth.isBefore(today)) return thisMonth;
  return candidate(now.year, now.month + 1);
}

/// Reminder fire-time for an event on [eventDate]: [daysBefore] days earlier
/// at [hour]:00. Returns null when that moment is already past.
DateTime? reminderMoment(
  DateTime eventDate,
  DateTime now, {
  int daysBefore = 0,
  int hour = 9,
}) {
  final at = DateTime(
    eventDate.year,
    eventDate.month,
    eventDate.day,
    hour,
  ).subtract(Duration(days: daysBefore));
  return at.isAfter(now) ? at : null;
}
