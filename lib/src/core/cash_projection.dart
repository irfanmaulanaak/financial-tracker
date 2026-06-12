/// Proyeksi sisa kas akhir siklus — perkiraan kasar, bukan angka resmi:
/// kas sekarang − tagihan terjadwal sisa siklus − estimasi belanja harian.
library;

class CashProjection {
  const CashProjection({
    required this.liquidNow,
    required this.upcomingBills,
    required this.estVariable,
  });

  /// Saldo kas + tabungan saat ini.
  final int liquidNow;

  /// Total tagihan terjadwal (kartu jatuh tempo + rutin) sampai akhir siklus.
  final int upcomingBills;

  /// Estimasi belanja variabel sisa siklus (rata-rata harian × hari tersisa).
  final int estVariable;

  int get projected => liquidNow - upcomingBills - estVariable;
}

/// [variableSpentSoFar] = pengeluaran non-rutin non-kartu siklus berjalan
/// (belanja kartu sudah terwakili lewat tagihan jatuh temponya).
CashProjection projectEndOfCycle({
  required int liquidNow,
  required int upcomingBillsTotal,
  required int variableSpentSoFar,
  required int daysElapsed,
  required int daysLeft,
}) {
  final perDay =
      daysElapsed <= 0 ? 0 : (variableSpentSoFar / daysElapsed).round();
  return CashProjection(
    liquidNow: liquidNow,
    upcomingBills: upcomingBillsTotal,
    estVariable: perDay * (daysLeft < 0 ? 0 : daysLeft),
  );
}
