import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final int amount;
  final String categoryId;
  final String paymentMethodId;
  final String? note;
  final String spentBy;
  final DateTime date;
  final bool recurring;
  final String? cardId;
  final String? installmentPlanId;
  final DateTime createdAt;
  final String createdBy;

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.paymentMethodId,
    required this.note,
    required this.spentBy,
    required this.date,
    required this.recurring,
    required this.cardId,
    required this.installmentPlanId,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'categoryId': categoryId,
        'paymentMethodId': paymentMethodId,
        if (note != null && note!.isNotEmpty) 'note': note,
        'spentBy': spentBy,
        'date': Timestamp.fromDate(date),
        'recurring': recurring,
        if (cardId != null) 'cardId': cardId,
        if (installmentPlanId != null) 'installmentPlanId': installmentPlanId,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };

  static Expense fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    return Expense(
      id: snap.id,
      amount: (m['amount'] as num).toInt(),
      categoryId: m['categoryId'] as String,
      paymentMethodId: m['paymentMethodId'] as String,
      note: m['note'] as String?,
      spentBy: m['spentBy'] as String,
      date: (m['date'] as Timestamp).toDate(),
      recurring: m['recurring'] as bool? ?? false,
      cardId: m['cardId'] as String?,
      installmentPlanId: m['installmentPlanId'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: m['createdBy'] as String,
    );
  }
}
