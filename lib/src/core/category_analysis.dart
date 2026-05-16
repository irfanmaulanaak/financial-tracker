/// Per-category spending analysis vs a rolling baseline.
///
/// `currentSpend` is what's been spent in the active window (e.g. current
/// budget cycle). `previousSpends` is a list of historical totals for the
/// same category over comparable past windows (e.g. last 3 cycles).
///
/// The analysis emits a verdict label + a delta vs the historical average:
///   * "Lebih hemat" — current < 90% of average
///   * "Stabil"      — current within ±10% of average
///   * "Boros"       — current > 110% of average (and 1.5x = "sangat boros")
library;

class CategoryAnalysis {
  final String categoryId;
  final int currentSpend;
  final int historicalAverage;
  final double deltaPct; // (current - avg) / avg ; positive = over
  final String verdict;

  const CategoryAnalysis({
    required this.categoryId,
    required this.currentSpend,
    required this.historicalAverage,
    required this.deltaPct,
    required this.verdict,
  });
}

CategoryAnalysis analyseCategory({
  required String categoryId,
  required int currentSpend,
  required List<int> previousSpends,
}) {
  if (previousSpends.isEmpty) {
    return CategoryAnalysis(
      categoryId: categoryId,
      currentSpend: currentSpend,
      historicalAverage: 0,
      deltaPct: 0,
      verdict: 'Belum cukup data',
    );
  }
  final avg =
      previousSpends.fold<int>(0, (a, b) => a + b) ~/ previousSpends.length;
  if (avg == 0 && currentSpend == 0) {
    return CategoryAnalysis(
      categoryId: categoryId,
      currentSpend: 0,
      historicalAverage: 0,
      deltaPct: 0,
      verdict: 'Tidak ada pengeluaran',
    );
  }
  if (avg == 0) {
    return CategoryAnalysis(
      categoryId: categoryId,
      currentSpend: currentSpend,
      historicalAverage: 0,
      deltaPct: 1.0,
      verdict: 'Baru muncul siklus ini',
    );
  }
  final delta = (currentSpend - avg) / avg;
  String verdict;
  if (delta >= 0.5) {
    verdict = 'Sangat boros';
  } else if (delta > 0.1) {
    verdict = 'Boros';
  } else if (delta < -0.1) {
    verdict = 'Lebih hemat';
  } else {
    verdict = 'Stabil';
  }
  return CategoryAnalysis(
    categoryId: categoryId,
    currentSpend: currentSpend,
    historicalAverage: avg,
    deltaPct: delta,
    verdict: verdict,
  );
}

/// Daily pattern: spending bucketed by day-of-week (Mon=1..Sun=7), normalised
/// to a 0..1 share. Returns a 7-element list indexed by weekday-1.
List<double> dailyPattern(List<({DateTime date, int amount})> records) {
  final buckets = List<int>.filled(7, 0);
  for (final r in records) {
    buckets[r.date.weekday - 1] += r.amount;
  }
  final total = buckets.fold<int>(0, (a, b) => a + b);
  if (total == 0) return List<double>.filled(7, 0);
  return [for (final b in buckets) b / total];
}
