import 'package:financial_tracker/src/features/investments/investment.dart';
import 'package:flutter_test/flutter_test.dart';

Investment _inv({
  required int v,
  required int c,
  InvestmentType type = InvestmentType.saham,
  String label = 'X',
}) =>
    Investment(
      id: label,
      label: label,
      type: type,
      currentValue: v,
      costBasis: c,
      updatedAt: DateTime(2025),
    );

void main() {
  group('Investment.gain', () {
    test('positive gain', () {
      final i = _inv(v: 1500, c: 1000);
      expect(i.gain, 500);
      expect(i.gainPct, closeTo(0.5, 0.001));
    });
    test('negative gain', () {
      final i = _inv(v: 800, c: 1000);
      expect(i.gain, -200);
      expect(i.gainPct, closeTo(-0.2, 0.001));
    });
    test('zero cost basis → 0% (avoids divide-by-zero)', () {
      final i = _inv(v: 100, c: 0);
      expect(i.gainPct, 0);
    });
  });

  group('summarisePortfolio', () {
    test('empty → all zero', () {
      final s = summarisePortfolio([]);
      expect(s.totalValue, 0);
      expect(s.totalCost, 0);
      expect(s.totalGain, 0);
      expect(s.distinctTypes, 0);
    });

    test('sums and counts distinct types (ignores zero-value positions)', () {
      final s = summarisePortfolio([
        _inv(v: 1000, c: 800, type: InvestmentType.saham),
        _inv(v: 2000, c: 1500, type: InvestmentType.reksadana),
        _inv(v: 500, c: 600, type: InvestmentType.saham), // same type
        _inv(v: 0, c: 100, type: InvestmentType.crypto), // zero-value → skip
      ]);
      expect(s.totalValue, 3500);
      expect(s.totalCost, 3000);
      expect(s.totalGain, 500);
      expect(s.distinctTypes, 2); // saham + reksadana
      expect(s.gainPct, closeTo(500 / 3000, 0.001));
    });
  });
}
