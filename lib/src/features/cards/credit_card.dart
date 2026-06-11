import 'package:cloud_firestore/cloud_firestore.dart';

class CreditCard {
  final String id;
  final String ownerId;
  final String label;
  final String last4;
  final int limit;

  /// "Limit terpakai" display figure, mirroring what the BCA app shows:
  /// billed-but-unpaid cicilan months + full pre-block for cicilan that
  /// haven't hit their first statement + plain unpaid charges. Jumps on the
  /// statement date (billingDay) by design — use [outstanding] for the real
  /// debt figure.
  final int used;

  /// True remaining obligation: plain unpaid charges + the FULL unpaid
  /// remainder of every active cicilan (billed or not). Date-independent,
  /// so net worth never jumps on statement day. Written by
  /// `CardRepository.recalcUsed`; legacy docs fall back to [used] until the
  /// first recalc.
  final int outstanding;

  /// Cumulative card payments allocated to plain (non-cicilan) charges.
  /// Incremented by the pay flows; `recalcUsed` subtracts it from the
  /// all-time plain expense sum so paid charges drop out of [used] /
  /// [outstanding] without touching expense history. Cicilan payments are
  /// NOT included here — those advance `monthsPaid` instead.
  final int plainPaid;
  final int dueDay;

  /// Day-of-month the bank closes the statement (e.g. BCA closes on the 12th
  /// then due on the 28th). Drives cicilan billing rollover in
  /// [cicilanBlocked] (the [used] display figure only). Legacy cards default
  /// to `max(1, dueDay - 16)` so the computed `used` stays sensible until the
  /// user edits the card.
  final int billingDay;
  final double apr;
  final String accent;
  final double minPaymentPct;

  const CreditCard({
    required this.id,
    required this.ownerId,
    required this.label,
    required this.last4,
    required this.limit,
    required this.used,
    required this.outstanding,
    this.plainPaid = 0,
    required this.dueDay,
    required this.billingDay,
    required this.apr,
    required this.accent,
    required this.minPaymentPct,
  });

  CreditCard copyWith({
    String? label,
    String? last4,
    int? limit,
    int? used,
    int? outstanding,
    int? plainPaid,
    int? dueDay,
    int? billingDay,
    double? apr,
    String? accent,
    double? minPaymentPct,
  }) =>
      CreditCard(
        id: id,
        ownerId: ownerId,
        label: label ?? this.label,
        last4: last4 ?? this.last4,
        limit: limit ?? this.limit,
        used: used ?? this.used,
        outstanding: outstanding ?? this.outstanding,
        plainPaid: plainPaid ?? this.plainPaid,
        dueDay: dueDay ?? this.dueDay,
        billingDay: billingDay ?? this.billingDay,
        apr: apr ?? this.apr,
        accent: accent ?? this.accent,
        minPaymentPct: minPaymentPct ?? this.minPaymentPct,
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'label': label,
        'last4': last4,
        'limit': limit,
        'used': used,
        'outstanding': outstanding,
        'plainPaid': plainPaid,
        'dueDay': dueDay,
        'billingDay': billingDay,
        'apr': apr,
        'accent': accent,
        'minPaymentPct': minPaymentPct,
      };

  static CreditCard fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    final dueDay = (m['dueDay'] as num?)?.toInt() ?? 1;
    final fallbackBilling = (dueDay - 16).clamp(1, 28).toInt();
    final billingDay = (m['billingDay'] as num?)?.toInt() ?? fallbackBilling;
    final used = (m['used'] as num?)?.toInt() ?? 0;
    return CreditCard(
      id: snap.id,
      ownerId: m['ownerId'] as String? ?? '',
      label: m['label'] as String? ?? '',
      last4: m['last4'] as String? ?? '',
      limit: (m['limit'] as num?)?.toInt() ?? 0,
      used: used,
      outstanding: (m['outstanding'] as num?)?.toInt() ?? used,
      plainPaid: (m['plainPaid'] as num?)?.toInt() ?? 0,
      dueDay: dueDay,
      billingDay: billingDay,
      apr: (m['apr'] as num?)?.toDouble() ?? 0.18,
      accent: m['accent'] as String? ?? '#3B82F6',
      minPaymentPct: (m['minPaymentPct'] as num?)?.toDouble() ?? 0.10,
    );
  }
}

class Installment {
  final String id;
  final String cardId;
  final String expenseId;
  final String label;
  final int total;
  final int monthly;
  final int monthsTotal;
  final int monthsPaid;
  final DateTime startedAt;

  const Installment({
    required this.id,
    required this.cardId,
    required this.expenseId,
    required this.label,
    required this.total,
    required this.monthly,
    required this.monthsTotal,
    required this.monthsPaid,
    required this.startedAt,
  });

  bool get isComplete => monthsPaid >= monthsTotal;
  int get remainingMonths => (monthsTotal - monthsPaid).clamp(0, monthsTotal);
  int get remainingAmount => remainingMonths * monthly;

  Map<String, dynamic> toMap() => {
        'expenseId': expenseId,
        'label': label,
        'total': total,
        'monthly': monthly,
        'monthsTotal': monthsTotal,
        'monthsPaid': monthsPaid,
        'startedAt': Timestamp.fromDate(startedAt),
      };

  static Installment fromSnapshot(DocumentSnapshot snap, String cardId) {
    final m = snap.data() as Map<String, dynamic>;
    return Installment(
      id: snap.id,
      cardId: cardId,
      expenseId: m['expenseId'] as String,
      label: m['label'] as String? ?? '',
      total: (m['total'] as num).toInt(),
      monthly: (m['monthly'] as num).toInt(),
      monthsTotal: (m['monthsTotal'] as num).toInt(),
      monthsPaid: (m['monthsPaid'] as num?)?.toInt() ?? 0,
      startedAt: (m['startedAt'] as Timestamp).toDate(),
    );
  }
}
