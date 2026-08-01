/// DSR = cicilan UTANG / gaji stabil PENUH (definisi OJK, batas 30%).
/// Biaya tetap non-utang (sewa) tidak ikut DSR tapi ikut mengurangi
/// uang siap pakai. Tagihan kartu 1× bayar bukan cicilan.
library;

const double dsrMaxOjk = 0.30;

({int totalMonthlyDebt, double dsr, int disposable}) debtServiceSummary({
  required int stableSalary,
  required int fixedObligationsMonthly,
  required int multiMonthCardMonthly,
  int nonDebtMonthly = 0,
}) {
  final debt = fixedObligationsMonthly + multiMonthCardMonthly;
  final dsr = stableSalary > 0 ? debt / stableSalary : 0.0;
  return (
    totalMonthlyDebt: debt,
    dsr: dsr,
    disposable: (stableSalary - debt - nonDebtMonthly).clamp(0, stableSalary),
  );
}

int budgetOvercommit({required int monthlyBudgetTotal, required int disposable}) {
  final over = monthlyBudgetTotal - disposable;
  return over > 0 ? over : 0;
}
