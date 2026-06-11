/// Household financial health score, 0-100. Per PLAN.md the full formula is
/// a weighted blend of 5 factors (weights sum to 100). When data is missing
/// for a factor, that factor's weight is redistributed to the remaining
/// factors so the score still falls on a clean 0-100 scale.
///
/// Factors:
///   * `disiplinPengeluaran` (30%) — budget adherence
///       1 - (spendThisCycle / monthlyBudget), clamped 0..1
///   * `rasioMenabung` (25%) — savings rate
///       (incomeThisCycle - spendThisCycle) / incomeThisCycle, clamped 0..1
///   * `danaDarurat` (20%) — emergency fund
///       savingsBalance / (avgMonthlySpend * 6), clamped 0..1
///       (6 months coverage = full marks)
///   * `bebanUtang` (15%) — debt burden (lower is better)
///       1 - (cardDebt / max(monthlyIncome * 6, 1)), clamped 0..1
///       (6 months income worth of debt = zero)
///   * `diversifikasiInvestasi` (10%) — # distinct investments / target
///       investmentCount / 5, clamped 0..1
library;

class HealthScoreInputs {
  final int spendThisCycle;
  final int incomeThisCycle;
  final int monthlyBudget;
  final int savingsBalance;
  final int cardDebt;
  final int avgMonthlySpend;
  final int investmentCount;

  const HealthScoreInputs({
    required this.spendThisCycle,
    required this.incomeThisCycle,
    required this.monthlyBudget,
    required this.savingsBalance,
    required this.cardDebt,
    required this.avgMonthlySpend,
    required this.investmentCount,
  });
}

class HealthFactor {
  final String key;
  final String label;
  final int weight;
  final double? rawScore01; // null = not enough data → weight redistributed
  final int? contribution;

  const HealthFactor({
    required this.key,
    required this.label,
    required this.weight,
    required this.rawScore01,
    required this.contribution,
  });
}

class HealthScore {
  final int score; // 0..100
  final String verdict;
  final List<HealthFactor> factors;

  const HealthScore({
    required this.score,
    required this.verdict,
    required this.factors,
  });

  /// Factor furthest from its ideal (lowest raw score with data), used for
  /// the "X paling perlu perhatian" hint. Null when no factor has data.
  HealthFactor? get weakestFactor {
    HealthFactor? weakest;
    for (final f in factors) {
      if (f.rawScore01 == null) continue;
      if (weakest == null || f.rawScore01! < weakest.rawScore01!) {
        weakest = f;
      }
    }
    return weakest;
  }
}

double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

HealthScore computeHealthScore(HealthScoreInputs i) {
  final raw = <(String, String, int, double?)>[
    (
      'disiplin',
      'Disiplin pengeluaran',
      30,
      i.monthlyBudget > 0
          ? _clamp01(1 - (i.spendThisCycle / i.monthlyBudget))
          : null,
    ),
    (
      'menabung',
      'Rasio menabung',
      25,
      i.incomeThisCycle > 0
          ? _clamp01(
              (i.incomeThisCycle - i.spendThisCycle) / i.incomeThisCycle)
          : null,
    ),
    (
      'darurat',
      'Dana darurat',
      20,
      i.avgMonthlySpend > 0
          ? _clamp01(i.savingsBalance / (i.avgMonthlySpend * 6))
          : null,
    ),
    (
      'utang',
      'Beban utang',
      15,
      i.incomeThisCycle > 0
          ? _clamp01(1 - (i.cardDebt / (i.incomeThisCycle * 6)))
          : null,
    ),
    (
      'investasi',
      'Diversifikasi investasi',
      10,
      _clamp01(i.investmentCount / 5),
    ),
  ];

  final totalWeightWithData =
      raw.where((r) => r.$4 != null).fold<int>(0, (a, r) => a + r.$3);

  // Exact (double) contribution per factor-with-data, in input order.
  final exact = <double?>[
    for (final r in raw)
      r.$4 == null
          ? null
          // Redistribute missing factor weights pro-rata across factors
          // with data.
          : r.$4! *
              (totalWeightWithData == 100
                  ? r.$3
                  : r.$3 * 100 / totalWeightWithData),
  ];
  final sumContrib = exact.whereType<double>().fold<double>(0, (a, b) => a + b);
  final score = totalWeightWithData == 0 ? 0 : sumContrib.round().clamp(0, 100);

  // Largest-remainder rounding so displayed contributions sum exactly to
  // `score` (independent rounding could drift by ±1-2 and read as a bug).
  final contribs = List<int?>.filled(exact.length, null);
  final remainders = <(int index, double frac)>[];
  var floorsSum = 0;
  for (var i = 0; i < exact.length; i++) {
    final e = exact[i];
    if (e == null) continue;
    final fl = e.floor();
    contribs[i] = fl;
    floorsSum += fl;
    remainders.add((i, e - fl));
  }
  remainders.sort((a, b) => b.$2.compareTo(a.$2));
  for (var k = 0; k < score - floorsSum && k < remainders.length; k++) {
    final i = remainders[k].$1;
    contribs[i] = contribs[i]! + 1;
  }

  final factors = <HealthFactor>[
    for (var i = 0; i < raw.length; i++)
      HealthFactor(
        key: raw[i].$1,
        label: raw[i].$2,
        weight: raw[i].$3,
        rawScore01: raw[i].$4,
        contribution: contribs[i],
      ),
  ];

  return HealthScore(
    score: score,
    verdict: verdictFor(score),
    factors: factors,
  );
}

String verdictFor(int score) {
  if (score >= 80) return 'Sangat sehat';
  if (score >= 65) return 'Sehat';
  if (score >= 50) return 'Cukup';
  if (score >= 30) return 'Perlu perbaikan';
  return 'Kritis';
}
