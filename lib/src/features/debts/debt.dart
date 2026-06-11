import 'package:cloud_firestore/cloud_firestore.dart';

/// Arah catatan: utang = keluarga berutang ke orang lain; piutang = orang
/// lain berutang ke keluarga.
enum DebtType { utang, piutang }

/// Catatan utang/piutang. Ledger murni — tidak mengubah saldo rekening.
class Debt {
  final String id;
  final DebtType type;
  final String counterparty;
  final int amount;
  final int paid;
  final String? note;
  final DateTime? dueDate;
  final bool settled;
  final DateTime createdAt;
  final String createdBy;

  const Debt({
    required this.id,
    required this.type,
    required this.counterparty,
    required this.amount,
    required this.paid,
    required this.note,
    required this.dueDate,
    required this.settled,
    required this.createdAt,
    required this.createdBy,
  });

  int get remaining {
    final left = amount - paid;
    return left < 0 ? 0 : left;
  }

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'counterparty': counterparty,
        'amount': amount,
        'paid': paid,
        if (note != null && note!.isNotEmpty) 'note': note,
        if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
        'settled': settled,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };

  static Debt fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    return Debt(
      id: snap.id,
      type: m['type'] == 'piutang' ? DebtType.piutang : DebtType.utang,
      counterparty: m['counterparty'] as String? ?? '',
      amount: (m['amount'] as num?)?.toInt() ?? 0,
      paid: (m['paid'] as num?)?.toInt() ?? 0,
      note: m['note'] as String?,
      dueDate: (m['dueDate'] as Timestamp?)?.toDate(),
      settled: m['settled'] as bool? ?? false,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: m['createdBy'] as String? ?? '',
    );
  }
}
