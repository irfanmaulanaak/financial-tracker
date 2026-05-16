/// Cicilan (installment) math for Indonesian credit cards.
///
/// Two interest models supported:
///   * `flat` — simple flat-rate per month on principal (the Indonesian
///     bank standard for promo cicilan, e.g. "3 bulan @ 0%", "6 bulan @ 1.5%/bln").
///     Each month: interest = principal * rate. Total interest = principal *
///     rate * months. Monthly payment = (principal + totalInterest) / months.
///   * `effective` — declining balance with monthly rate = APR / 12 (more
///     accurate for non-promo cicilan; used for some retail installment plans).
///
/// `apr` is the annual percentage rate (e.g. 0.18 for 18%/year).
library;

enum InterestModel { flat, effective }

class CicilanPlan {
  /// Total amount to be repaid (principal + interest), in IDR.
  final int total;

  /// Total interest charged over the plan, in IDR.
  final int totalInterest;

  /// Monthly payment, in IDR (rounded to nearest rupiah).
  final int monthly;

  /// Number of months in the plan.
  final int months;

  /// Original principal (purchase amount), in IDR.
  final int principal;

  /// APR used for the calculation.
  final double apr;

  /// Model used.
  final InterestModel model;

  const CicilanPlan({
    required this.total,
    required this.totalInterest,
    required this.monthly,
    required this.months,
    required this.principal,
    required this.apr,
    required this.model,
  });

  @override
  String toString() =>
      'CicilanPlan(principal=$principal, months=$months, apr=$apr, model=$model, '
      'monthly=$monthly, total=$total)';
}

/// Computes a cicilan plan. `principal` must be > 0 and `months` >= 1.
/// For 0% APR, returns a plan with zero interest regardless of model.
CicilanPlan computeCicilan({
  required int principal,
  required int months,
  required double apr,
  InterestModel model = InterestModel.flat,
}) {
  if (principal <= 0) {
    throw ArgumentError.value(principal, 'principal', 'must be > 0');
  }
  if (months < 1) {
    throw ArgumentError.value(months, 'months', 'must be >= 1');
  }
  if (apr < 0) {
    throw ArgumentError.value(apr, 'apr', 'must be >= 0');
  }

  if (apr == 0) {
    final monthly = (principal / months).round();
    return CicilanPlan(
      total: principal,
      totalInterest: 0,
      monthly: monthly,
      months: months,
      principal: principal,
      apr: 0,
      model: model,
    );
  }

  switch (model) {
    case InterestModel.flat:
      final monthlyRate = apr / 12;
      final totalInterest = (principal * monthlyRate * months).round();
      final total = principal + totalInterest;
      final monthly = (total / months).round();
      return CicilanPlan(
        total: total,
        totalInterest: totalInterest,
        monthly: monthly,
        months: months,
        principal: principal,
        apr: apr,
        model: model,
      );

    case InterestModel.effective:
      // Standard amortising loan formula:
      // M = P * r / (1 - (1 + r)^-n)
      final r = apr / 12;
      final factor = r / (1 - _pow(1 + r, -months));
      final monthly = (principal * factor).round();
      final total = monthly * months;
      return CicilanPlan(
        total: total,
        totalInterest: total - principal,
        monthly: monthly,
        months: months,
        principal: principal,
        apr: apr,
        model: model,
      );
  }
}

double _pow(double base, int exp) {
  // dart:math.pow returns num; explicit handling for negative exp.
  var result = 1.0;
  final positive = exp.abs();
  for (var i = 0; i < positive; i++) {
    result *= base;
  }
  return exp < 0 ? 1 / result : result;
}

/// Minimum payment on a credit card given balance + minPaymentPct (e.g. 0.10).
/// Returns the larger of the percentage-based minimum and a hard floor of
/// Rp50.000 (typical Indonesian CC), capped to the outstanding balance.
int minimumPayment({
  required int balance,
  required double minPaymentPct,
  int floor = 50000,
}) {
  if (balance <= 0) return 0;
  final pct = (balance * minPaymentPct).round();
  final raw = pct < floor ? floor : pct;
  return raw > balance ? balance : raw;
}
