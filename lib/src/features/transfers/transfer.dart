import 'package:cloud_firestore/cloud_firestore.dart';

/// A single move-money operation between two of the household's tracked
/// accounts (cash ↔ savings, in any direction). The repo decrements the
/// source by `amount + fee` and increments the destination by `amount`
/// in one transaction; the fee is "lost" (operator fee, top-up surcharge,
/// transfer fee — money leaves the household but never lands anywhere).
///
/// Fees are NOT auto-recorded as expenses. They show up only as the gap
/// between source debit and destination credit on the household's balance
/// sheet. If you want them in your category breakdown, log a manual
/// expense in a "Biaya Bank" category alongside.
class Transfer {
  final String id;
  final int amount;
  final int fee;
  final String sourceAccountId;
  final String destinationAccountId;
  final String? note;
  final String transferredBy;
  final DateTime date;
  final DateTime createdAt;
  final String createdBy;

  const Transfer({
    required this.id,
    required this.amount,
    required this.fee,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.note,
    required this.transferredBy,
    required this.date,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'fee': fee,
        'sourceAccountId': sourceAccountId,
        'destinationAccountId': destinationAccountId,
        if (note != null && note!.isNotEmpty) 'note': note,
        'transferredBy': transferredBy,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };

  static Transfer fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    return Transfer(
      id: snap.id,
      amount: (m['amount'] as num).toInt(),
      fee: (m['fee'] as num?)?.toInt() ?? 0,
      sourceAccountId: m['sourceAccountId'] as String,
      destinationAccountId: m['destinationAccountId'] as String,
      note: m['note'] as String?,
      transferredBy: m['transferredBy'] as String,
      date: (m['date'] as Timestamp).toDate(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: m['createdBy'] as String,
    );
  }
}
