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
  /// pokok — net worth hanya pakai field ini.
  final int? outstandingPrincipal;
  final DateTime startedAt;
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
    required this.createdBy,
  });

  bool get isComplete => monthsPaid >= monthsTotal;
  int get remainingMonths => (monthsTotal - monthsPaid).clamp(0, monthsTotal);

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
      createdBy: m['createdBy'] as String? ?? '',
    );
  }
}
