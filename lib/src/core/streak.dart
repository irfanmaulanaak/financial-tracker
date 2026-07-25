/// Recording-streak math. Pure so thresholds are unit-testable.
///
/// Tone guard (per UX research): streaks celebrate, never guilt-trip.
/// Callers hide the streak UI entirely below [minVisibleStreak] instead of
/// showing "0 hari".
///
/// Forgiveness (riset streak 2026 — broken streak = quit moment, bukan
/// restart moment): satu hari bolong TIDAK memutus rantai ([grace] = 1).
/// Bolong kedua baru memutus. Hari bolong tidak ikut dihitung.
library;

const minVisibleStreak = 2;

/// Consecutive days with at least one recorded expense, counting back from
/// [today]. If today has no entry yet, counting starts from yesterday —
/// opening the app before recording shouldn't show a broken streak.
///
/// Up to [grace] missing days are skipped without breaking the chain
/// (they don't add to the count).
///
/// [daysWithEntries] must contain day-key dates (midnight local).
int recordingStreak({
  required Set<DateTime> daysWithEntries,
  required DateTime today,
  int grace = 1,
}) {
  final t = DateTime(today.year, today.month, today.day);
  var cursor =
      daysWithEntries.contains(t) ? t : t.subtract(const Duration(days: 1));
  var streak = 0;
  var graceLeft = grace;
  while (true) {
    if (daysWithEntries.contains(cursor)) {
      streak++;
    } else if (graceLeft > 0) {
      graceLeft--;
    } else {
      break;
    }
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Supportive copy per streak length (id-ID).
String streakLabel(int streak) {
  if (streak >= 30) return '$streak hari beruntun tercatat';
  if (streak >= 7) return '$streak hari beruntun tercatat';
  return '$streak hari beruntun tercatat';
}
