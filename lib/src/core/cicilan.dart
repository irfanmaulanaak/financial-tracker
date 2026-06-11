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

/// Counts how many statement-closing days have passed since `startedAt`,
/// i.e. how many of a cicilan's installments the bank should have rolled into
/// a bill by `today`.
///
/// Rule (mirrors BCA's behaviour):
///   * If `startedAt <= billingDay-of-its-month`, the first billing crosses
///     on the SAME month's billing day.
///   * Otherwise the first crossing is the NEXT month's billing day.
/// Subsequent crossings are one per month thereafter.
///
/// Returns 0 if no billing day has passed yet. Result is unbounded — callers
/// cap at `monthsTotal` when computing per-cicilan amounts.
int computeMonthsBilled({
  required DateTime startedAt,
  required DateTime today,
  required int billingDay,
}) {
  if (!today.isAfter(startedAt) && !_sameDay(today, startedAt)) return 0;
  final start = DateTime(startedAt.year, startedAt.month, startedAt.day);
  final now = DateTime(today.year, today.month, today.day);
  // First billing date is in start's month if start.day <= billingDay,
  // otherwise next month.
  final firstBillingMonth = start.day <= billingDay
      ? DateTime(start.year, start.month, 1)
      : DateTime(start.year, start.month + 1, 1);
  final firstBillingDate = _clampToMonth(
    firstBillingMonth.year,
    firstBillingMonth.month,
    billingDay,
  );
  if (now.isBefore(firstBillingDate)) return 0;
  // Months between firstBillingMonth and now (inclusive of firstBillingMonth
  // when today >= firstBillingDate, plus any subsequent months whose billing
  // day has passed).
  var count = 0;
  var cursor = firstBillingMonth;
  while (true) {
    final billingDate =
        _clampToMonth(cursor.year, cursor.month, billingDay);
    if (now.isBefore(billingDate)) break;
    count += 1;
    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }
  return count;
}

/// Per-cicilan contribution to `card.used` under the BCA-style model:
///   * If no billing has crossed yet (`monthsBilled == 0`), the bank still
///     reserves the full unpaid principal+interest — this matches BCA's
///     behaviour of pre-blocking just-approved cicilan.
///   * Otherwise only the rolled-over-but-unpaid installments are blocked.
///
/// Inputs come from the [Installment] doc and the card's `billingDay`.
int cicilanBlocked({
  required int monthsTotal,
  required int monthsPaid,
  required int monthly,
  required DateTime startedAt,
  required DateTime today,
  required int billingDay,
}) {
  if (monthsPaid >= monthsTotal) return 0;
  final billed = computeMonthsBilled(
    startedAt: startedAt,
    today: today,
    billingDay: billingDay,
  );
  if (billed == 0) {
    return (monthsTotal - monthsPaid) * monthly;
  }
  final cappedBilled = billed > monthsTotal ? monthsTotal : billed;
  final unpaidBilled = cappedBilled - monthsPaid;
  return unpaidBilled <= 0 ? 0 : unpaidBilled * monthly;
}

DateTime _clampToMonth(int year, int month, int day) {
  // 0th day of next month == last day of `month`. Used to clamp billingDay
  // for short months (Feb 30 -> Feb 28/29).
  final lastDay = DateTime(year, month + 1, 0).day;
  final d = day > lastDay ? lastDay : day;
  return DateTime(year, month, d);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Minimal cicilan state needed for card debt math. Mirrors the
/// `Installment` doc fields (kept primitive so core stays Firestore-free).
typedef CicilanPlanState = ({
  int monthsTotal,
  int monthsPaid,
  int monthly,
  DateTime startedAt,
});

/// The card's two debt figures, computed from raw state:
///
///   * `used` — BCA-display "limit terpakai": billed-but-unpaid cicilan
///     months (pre-block full remainder before the first statement) + plain
///     charges not yet covered by payments. Moves on the statement date.
///   * `outstanding` — true remaining obligation: FULL unpaid remainder of
///     every cicilan + unpaid plain charges. Date-independent — this is the
///     net-worth debt figure, so statement day never moves net worth.
///
/// `plainTotal` is the all-time sum of non-cicilan card expenses;
/// `plainPaid` is the cumulative amount of card payments allocated to those
/// charges (clamped here so deleted expenses can't push it negative).
({int used, int outstanding}) cardDebtTotals({
  required int plainTotal,
  required int plainPaid,
  required List<CicilanPlanState> plans,
  required DateTime today,
  required int billingDay,
}) {
  final plainOutstanding = (plainTotal - plainPaid).clamp(0, plainTotal);
  var blocked = 0;
  var remaining = 0;
  for (final p in plans) {
    blocked += cicilanBlocked(
      monthsTotal: p.monthsTotal,
      monthsPaid: p.monthsPaid,
      monthly: p.monthly,
      startedAt: p.startedAt,
      today: today,
      billingDay: billingDay,
    );
    final months = (p.monthsTotal - p.monthsPaid).clamp(0, p.monthsTotal);
    remaining += months * p.monthly;
  }
  return (
    used: blocked + plainOutstanding,
    outstanding: remaining + plainOutstanding,
  );
}
