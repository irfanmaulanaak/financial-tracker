/// Payday-based budget cycle math.
///
/// Household payday is a day-of-month (1-31). If that day lands on Sat/Sun,
/// the payday rolls *back* to the prior weekday (Friday). The cycle for any
/// date is `[paydayThisCycle, paydayNextCycle)`.
library;

/// Adjusts a target day-of-month to a real `DateTime` in the given year/month,
/// applying weekend rollback. If `day` exceeds the month length, the last
/// valid day of the month is used instead (e.g. payday 31 in February).
DateTime resolvePayday(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  final clamped = day > lastDay ? lastDay : day;
  var date = DateTime(year, month, clamped);
  while (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
    date = date.subtract(const Duration(days: 1));
  }
  return date;
}

/// Returns the (start, endExclusive) bounds of the current budget cycle.
/// `start` is the most recent payday on/before `now`. `endExclusive` is the
/// next payday after `start`.
({DateTime start, DateTime endExclusive}) currentCycle(
  DateTime now, {
  required int payday,
}) {
  // First check if this month's payday is still in the future for `now`.
  // If yes, the active cycle started from the previous month's payday.
  final thisMonthPayday = resolvePayday(now.year, now.month, payday);
  final start = !now.isBefore(thisMonthPayday)
      ? thisMonthPayday
      : resolvePayday(now.year, now.month - 1, payday);
  // Payday 1-2 + weekend rollback bisa membuat payday bulan berikutnya
  // jatuh di tanggal yang sama dengan start (siklus 0 hari) — maju terus
  // sampai benar-benar lewat start.
  var m = 1;
  var endExclusive = resolvePayday(start.year, start.month + m, payday);
  while (!endExclusive.isAfter(start)) {
    m++;
    endExclusive = resolvePayday(start.year, start.month + m, payday);
  }
  return (start: start, endExclusive: endExclusive);
}

/// Number of days in the current cycle (inclusive of start, exclusive of end).
int cycleLengthDays(({DateTime start, DateTime endExclusive}) cycle) {
  return cycle.endExclusive.difference(cycle.start).inDays;
}
