import 'package:cloud_firestore/cloud_firestore.dart';

/// Investments are stored as `households/{hid}/investments/{id}`. Pooled
/// (no per-member breakdown) per PLAN.md. Manual entries only in MVP.
enum InvestmentType { saham, reksadana, deposito, crypto, emas, lainnya }

String investmentTypeLabel(InvestmentType t) => switch (t) {
      InvestmentType.saham => 'Saham',
      InvestmentType.reksadana => 'Reksadana',
      InvestmentType.deposito => 'Deposito',
      InvestmentType.crypto => 'Crypto',
      InvestmentType.emas => 'Emas',
      InvestmentType.lainnya => 'Lainnya',
    };

InvestmentType investmentTypeFromString(String? s) =>
    InvestmentType.values.firstWhere((e) => e.name == s,
        orElse: () => InvestmentType.lainnya);

class Investment {
  final String id;
  final String label;
  final InvestmentType type;
  final int currentValue;
  final int costBasis;
  final DateTime updatedAt;

  const Investment({
    required this.id,
    required this.label,
    required this.type,
    required this.currentValue,
    required this.costBasis,
    required this.updatedAt,
  });

  int get gain => currentValue - costBasis;
  double get gainPct => costBasis == 0 ? 0 : gain / costBasis;

  Map<String, dynamic> toMap() => {
        'label': label,
        'type': type.name,
        'currentValue': currentValue,
        'costBasis': costBasis,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  static Investment fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    return Investment(
      id: snap.id,
      label: m['label'] as String? ?? '',
      type: investmentTypeFromString(m['type'] as String?),
      currentValue: (m['currentValue'] as num?)?.toInt() ?? 0,
      costBasis: (m['costBasis'] as num?)?.toInt() ?? 0,
      updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Portfolio totals + simple diversification (# distinct non-zero types).
class PortfolioSummary {
  final int totalValue;
  final int totalCost;
  final int totalGain;
  final int distinctTypes;

  const PortfolioSummary({
    required this.totalValue,
    required this.totalCost,
    required this.totalGain,
    required this.distinctTypes,
  });

  double get gainPct => totalCost == 0 ? 0 : totalGain / totalCost;
}

PortfolioSummary summarisePortfolio(Iterable<Investment> investments) {
  var v = 0, c = 0;
  final types = <InvestmentType>{};
  for (final i in investments) {
    v += i.currentValue;
    c += i.costBasis;
    if (i.currentValue > 0) types.add(i.type);
  }
  return PortfolioSummary(
    totalValue: v,
    totalCost: c,
    totalGain: v - c,
    distinctTypes: types.length,
  );
}
