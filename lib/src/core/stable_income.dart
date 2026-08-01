/// Gaji stabil = rata-rata gaji per siklus lengkap (siklus berjalan tidak
/// ikut — gajinya bisa baru masuk sebagian). Pembagi rasio.
library;

import 'payday.dart';

int stableSalary({
  required List<({DateTime date, int amount})> salaryIncomes,
  required DateTime now,
  required int payday,
  int lookbackCycles = 3,
}) {
  final current = currentCycle(now, payday: payday);
  final sums = <int>[];
  var endExclusive = current.start;
  for (var i = 0; i < lookbackCycles; i++) {
    final probe = endExclusive.subtract(const Duration(days: 1));
    final cycle = currentCycle(probe, payday: payday);
    var sum = 0;
    for (final inc in salaryIncomes) {
      if (!inc.date.isBefore(cycle.start) &&
          inc.date.isBefore(cycle.endExclusive)) {
        sum += inc.amount;
      }
    }
    if (sum > 0) sums.add(sum);
    endExclusive = cycle.start;
  }
  if (sums.isEmpty) return 0;
  return sums.reduce((a, b) => a + b) ~/ sums.length;
}
