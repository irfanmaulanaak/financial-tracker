/// Utang/piutang ledger math. Catatan saja — tidak menyentuh saldo
/// rekening; pencatatan arus kas tetap lewat pengeluaran/pemasukan.
library;

/// Applies a repayment to a debt. Payment clamps into [0, amount] so a
/// final "bayar lunas" can never overshoot; settled = fully repaid.
({int paid, bool settled}) applyDebtPayment({
  required int amount,
  required int paid,
  required int payment,
}) {
  var next = paid + payment;
  if (next < 0) next = 0;
  if (next > amount) next = amount;
  return (paid: next, settled: next >= amount);
}
