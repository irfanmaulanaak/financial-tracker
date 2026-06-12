/// Envelope ("amplop") budget math with optional per-category rollover.
///
/// Rollover policy (kept deliberately simple — one-cycle lookback,
/// non-compounding):
///   carry = max(0, monthlyBudget − prevCycleSpent)
///   effectiveBudget = monthlyBudget + carry        (when rollover enabled)
///
/// Overspending last cycle never *reduces* this cycle's envelope (no debt
/// carry) — supportive, not punitive, per the UX research.
library;

/// Leftover from the previous cycle that may roll into the current one.
/// Never negative; never more than one full budget.
int carryOver({required int monthlyBudget, required int prevCycleSpent}) {
  if (monthlyBudget <= 0) return 0;
  final left = monthlyBudget - prevCycleSpent;
  return left < 0 ? 0 : left;
}

/// Budget to measure this cycle's spending against.
int effectiveBudget({
  required int monthlyBudget,
  required bool rollover,
  required int prevCycleSpent,
}) {
  if (!rollover || monthlyBudget <= 0) return monthlyBudget;
  return monthlyBudget +
      carryOver(monthlyBudget: monthlyBudget, prevCycleSpent: prevCycleSpent);
}
