/// Pure date math for the installment "month path" (DESIGN.md section 6,
/// item 2): one dot per month, from the plan's start month to its last one.
library;

/// The month a plan with [monthsTotal] months finishes in, given it
/// [startedAt]. Only year/month matter — the day is ignored.
DateTime monthPathEndMonth(DateTime startedAt, int monthsTotal) {
  final total = monthsTotal < 1 ? 1 : monthsTotal;
  return DateTime(startedAt.year, startedAt.month + (total - 1));
}

/// Bubble copy shown after "Bayar 1 bulan" advances the plan by one month,
/// while it isn't finished yet.
String monthPathBumpLine(int monthsRemaining) =>
    'Mantap! Tinggal $monthsRemaining bulan lagi.';
