import 'package:cloud_firestore/cloud_firestore.dart';

class CreditCard {
  final String id;
  final String ownerId;
  final String label;
  final String last4;
  final int limit;
  final int used;
  final int dueDay;
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
    required this.dueDay,
    required this.apr,
    required this.accent,
    required this.minPaymentPct,
  });

  CreditCard copyWith({
    String? label,
    String? last4,
    int? limit,
    int? used,
    int? dueDay,
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
        dueDay: dueDay ?? this.dueDay,
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
        'dueDay': dueDay,
        'apr': apr,
        'accent': accent,
        'minPaymentPct': minPaymentPct,
      };

  static CreditCard fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    return CreditCard(
      id: snap.id,
      ownerId: m['ownerId'] as String? ?? '',
      label: m['label'] as String? ?? '',
      last4: m['last4'] as String? ?? '',
      limit: (m['limit'] as num?)?.toInt() ?? 0,
      used: (m['used'] as num?)?.toInt() ?? 0,
      dueDay: (m['dueDay'] as num?)?.toInt() ?? 1,
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
  // Derive from `total` not `remainingMonths * monthly` to avoid the rounding
  // drift that bites when monthly = round(total / months) doesn't divide
  // evenly (e.g. 11_800_000 / 12 → 983_333, leaving 4 IDR stranded on the
  // card on delete). Either edge stays exact:
  //   - monthsPaid == 0           → remainingAmount = total
  //   - monthsPaid >= monthsTotal → remainingAmount = 0
  int get remainingAmount {
    if (monthsPaid <= 0) return total;
    if (monthsPaid >= monthsTotal) return 0;
    return (total - monthly * monthsPaid).clamp(0, total);
  }

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
