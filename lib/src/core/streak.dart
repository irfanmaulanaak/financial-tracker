/// Recording-streak math. Pure so thresholds are unit-testable.
///
/// Tone guard (per UX research): streaks celebrate, never guilt-trip.
/// Callers hide the streak UI entirely below [minVisibleStreak] instead of
/// showing "0 hari".
library;

const minVisibleStreak = 2;

/// Consecutive days with at least one recorded expense, counting back from
/// [today]. If today has no entry yet, counting starts from yesterday —
/// opening the app before recording shouldn't show a broken streak.
///
/// [daysWithEntries] must contain day-key dates (midnight local).
int recordingStreak({
  required Set<DateTime> daysWithEntries,
  required DateTime today,
}) {
  final t = DateTime(today.year, today.month, today.day);
  var cursor =
      daysWithEntries.contains(t) ? t : t.subtract(const Duration(days: 1));
  var streak = 0;
  while (daysWithEntries.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Supportive copy per streak length (id-ID).
String streakLabel(int streak) {
  if (streak >= 30) return '$streak hari beruntun — kebiasaan terbentuk!';
  if (streak >= 7) return '$streak hari beruntun — konsisten sekali!';
  return '$streak hari beruntun tercatat';
}
