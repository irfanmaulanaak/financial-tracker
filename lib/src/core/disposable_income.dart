/// DSR = cicilan / gaji stabil PENUH (definisi OJK, batas 30%).
/// Uang siap pakai = gaji stabil − cicilan; hanya untuk budget/safe-to-spend.
/// Tagihan kartu 1× bayar bukan cicilan — tidak ikut DSR.
library;

const double dsrMaxOjk = 0.30;

({int totalMonthlyDebt, double dsr, int disposable}) debtServiceSummary({
  required int stableSalary,
  required int fixedObligationsMonthly,
  required int multiMonthCardMonthly,
}) {
  final total = fixedObligationsMonthly + multiMonthCardMonthly;
  final dsr = stableSalary > 0 ? total / stableSalary : 0.0;
  return (
    totalMonthlyDebt: total,
    dsr: dsr,
    disposable: (stableSalary - total).clamp(0, stableSalary),
  );
}

int budgetOvercommit({required int monthlyBudgetTotal, required int disposable}) {
  final over = monthlyBudgetTotal - disposable;
  return over > 0 ? over : 0;
}
