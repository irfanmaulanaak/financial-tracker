import 'package:cloud_firestore/cloud_firestore.dart';

/// Cicilan tetap non-kartu (leasing mobil, KPR) atau biaya tetap non-utang
/// (sewa). Bayar = kurangi saldo rekening, TIDAK makan budget kategori.
/// Hanya `isDebt` yang ikut DSR; dua-duanya mengurangi uang siap pakai.
class Obligation {
  final String id;
  final String label;
  final int monthly;
  final int monthsTotal;
  final int monthsPaid;
  final int dueDay;
  final bool isDebt;

  /// Sisa pokok (opsional). `monthly × sisa bulan` termasuk bunga, bukan
  /// pokok — net worth hanya pakai field ini. Tidak dikurangi otomatis
  /// saat bayar (angsuran termasuk bunga); user update manual dari
  /// info leasing/bank.
  final int? outstandingPrincipal;
  final DateTime startedAt;
  final DateTime? lastPaidAt;
  final String createdBy;

  const Obligation({
    required this.id,
    required this.label,
    required this.monthly,
    required this.monthsTotal,
    required this.monthsPaid,
    required this.dueDay,
    this.isDebt = true,
    required this.outstandingPrincipal,
    required this.startedAt,
    this.lastPaidAt,
    required this.createdBy,
  });

  bool get isComplete => monthsPaid >= monthsTotal;
  int get remainingMonths => (monthsTotal - monthsPaid).clamp(0, monthsTotal);

  /// Sudah dibayar untuk jatuh tempo di bulan [dueDate]? Meredam banner/
  /// notifikasi/kalender setelah user menandai bayar bulan itu.
  bool paidForMonth(DateTime dueDate) =>
      lastPaidAt != null &&
      lastPaidAt!.year == dueDate.year &&
      lastPaidAt!.month == dueDate.month;

  Map<String, dynamic> toMap() => {
        'label': label,
        'monthly': monthly,
        'monthsTotal': monthsTotal,
        'monthsPaid': monthsPaid,
        'dueDay': dueDay,
        'isDebt': isDebt,
        if (outstandingPrincipal != null)
          'outstandingPrincipal': outstandingPrincipal,
        'startedAt': Timestamp.fromDate(startedAt),
        if (lastPaidAt != null) 'lastPaidAt': Timestamp.fromDate(lastPaidAt!),
        'createdBy': createdBy,
      };

  static Obligation fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    return Obligation(
      id: snap.id,
      label: m['label'] as String? ?? '',
      monthly: (m['monthly'] as num?)?.toInt() ?? 0,
      monthsTotal: (m['monthsTotal'] as num?)?.toInt() ?? 1,
      monthsPaid: (m['monthsPaid'] as num?)?.toInt() ?? 0,
      dueDay: (m['dueDay'] as num?)?.toInt() ?? 1,
      isDebt: m['isDebt'] as bool? ?? true,
      outstandingPrincipal: (m['outstandingPrincipal'] as num?)?.toInt(),
      startedAt: (m['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPaidAt: (m['lastPaidAt'] as Timestamp?)?.toDate(),
      createdBy: m['createdBy'] as String? ?? '',
    );
  }
}
