import 'package:cloud_firestore/cloud_firestore.dart';

/// Source labels — UI presents these as a fixed picker.
enum IncomeSource { salary, freelance, invest, gift, refund, other }

String incomeSourceLabel(IncomeSource s) => switch (s) {
      IncomeSource.salary => 'Gaji',
      IncomeSource.freelance => 'Freelance',
      IncomeSource.invest => 'Investasi',
      IncomeSource.gift => 'Hadiah',
      IncomeSource.refund => 'Refund',
      IncomeSource.other => 'Lainnya',
    };

IncomeSource incomeSourceFromString(String? s) => switch (s) {
      'salary' => IncomeSource.salary,
      'freelance' => IncomeSource.freelance,
      'invest' => IncomeSource.invest,
      'gift' => IncomeSource.gift,
      'refund' => IncomeSource.refund,
      _ => IncomeSource.other,
    };

class Income {
  final String id;
  final int amount;
  final IncomeSource source;
  final String destinationAccountId;
  final String? note;
  final String receivedBy;
  final DateTime date;
  final bool recurring;
  final DateTime createdAt;
  final String createdBy;

  const Income({
    required this.id,
    required this.amount,
    required this.source,
    required this.destinationAccountId,
    required this.note,
    required this.receivedBy,
    required this.date,
    required this.recurring,
    required this.createdAt,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'sourceId': source.name,
        'destinationAccountId': destinationAccountId,
        if (note != null && note!.isNotEmpty) 'note': note,
        'receivedBy': receivedBy,
        'date': Timestamp.fromDate(date),
        'recurring': recurring,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };

  static Income fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    return Income(
      id: snap.id,
      amount: (m['amount'] as num).toInt(),
      source: incomeSourceFromString(m['sourceId'] as String?),
      destinationAccountId: m['destinationAccountId'] as String,
      note: m['note'] as String?,
      receivedBy: m['receivedBy'] as String,
      date: (m['date'] as Timestamp).toDate(),
      recurring: m['recurring'] as bool? ?? false,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: m['createdBy'] as String,
    );
  }
}
