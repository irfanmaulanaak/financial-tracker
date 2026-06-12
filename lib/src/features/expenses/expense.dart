import 'package:cloud_firestore/cloud_firestore.dart';

/// Permintaan cek transaksi: satu anggota minta anggota lain meninjau.
/// Disimpan inline di doc expense sebagai map `review` — satu permintaan
/// aktif per transaksi (cukup untuk rumah tangga 2-5 orang).
class ReviewRequest {
  final String by;
  final String to;
  final bool done;
  final DateTime at;

  const ReviewRequest({
    required this.by,
    required this.to,
    required this.done,
    required this.at,
  });

  Map<String, dynamic> toMap() => {
        'by': by,
        'to': to,
        'done': done,
        'at': Timestamp.fromDate(at),
      };

  static ReviewRequest? fromMap(Map<String, dynamic>? m) {
    if (m == null) return null;
    return ReviewRequest(
      by: m['by'] as String? ?? '',
      to: m['to'] as String? ?? '',
      done: m['done'] as bool? ?? false,
      at: (m['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class Expense {
  final String id;
  final int amount;
  final String categoryId;

  /// LEGACY. Old rows persisted a `paymentMethods[].id` reference here
  /// (e.g. 'cash', 'gopay'). New rows leave this null — the actual source
  /// of money is tracked via [sourceAccountId] (cash flow) or [cardId]
  /// (credit-card flow). Kept on the model so existing rows still parse;
  /// CSV/export flows resolve from sourceAccountId / cardId first.
  final String? paymentMethodId;
  final String? note;
  final String spentBy;
  final DateTime date;
  final bool recurring;
  final String? cardId;
  final String? installmentPlanId;

  /// Cash/debit/e-wallet expense: id of the household cash- or savings-account
  /// the money was debited from. Repo decrements the matching account in the
  /// same txn that writes this row, and refunds it on delete. Null for
  /// credit-card expenses (those bump `card.used` instead) and for legacy
  /// rows recorded before this field existed.
  final String? sourceAccountId;
  final DateTime createdAt;
  final String createdBy;

  /// Emoji reactions: `{uid: emoji}` — one reaction per member, stored on
  /// the doc itself (no subcollection read needed for list rows).
  final Map<String, String> reactions;

  /// Permintaan cek aktif (null = tidak ada). Jangan hilangkan saat edit.
  final ReviewRequest? review;

  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    this.paymentMethodId,
    required this.note,
    required this.spentBy,
    required this.date,
    required this.recurring,
    required this.cardId,
    required this.installmentPlanId,
    required this.sourceAccountId,
    required this.createdAt,
    required this.createdBy,
    this.reactions = const {},
    this.review,
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'categoryId': categoryId,
        if (paymentMethodId != null) 'paymentMethodId': paymentMethodId,
        if (note != null && note!.isNotEmpty) 'note': note,
        'spentBy': spentBy,
        'date': Timestamp.fromDate(date),
        'recurring': recurring,
        if (cardId != null) 'cardId': cardId,
        if (installmentPlanId != null) 'installmentPlanId': installmentPlanId,
        if (sourceAccountId != null) 'sourceAccountId': sourceAccountId,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
        if (reactions.isNotEmpty) 'reactions': reactions,
        if (review != null) 'review': review!.toMap(),
      };

  static Expense fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    return Expense(
      id: snap.id,
      amount: (m['amount'] as num).toInt(),
      categoryId: m['categoryId'] as String,
      paymentMethodId: m['paymentMethodId'] as String?,
      note: m['note'] as String?,
      spentBy: m['spentBy'] as String,
      date: (m['date'] as Timestamp).toDate(),
      recurring: m['recurring'] as bool? ?? false,
      cardId: m['cardId'] as String?,
      installmentPlanId: m['installmentPlanId'] as String?,
      sourceAccountId: m['sourceAccountId'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: m['createdBy'] as String,
      reactions: Map<String, String>.from(
          m['reactions'] as Map<String, dynamic>? ?? const {}),
      review:
          ReviewRequest.fromMap(m['review'] as Map<String, dynamic>?),
    );
  }
}
