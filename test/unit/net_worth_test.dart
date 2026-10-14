import 'package:financial_tracker/src/core/net_worth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeNetWorth', () {
    test('empty inputs → all zero', () {
      final nw = computeNetWorth(cash: [], savings: [], cards: []);
      expect(nw.cash, 0);
      expect(nw.savings, 0);
      expect(nw.debt, 0);
      expect(nw.assets, 0);
      expect(nw.total, 0);
    });

    test('sums cash + savings, subtracts card debt', () {
      final nw = computeNetWorth(
        cash: const [
          AccountBalance(id: 'a', label: 'Dompet', value: 500000),
          AccountBalance(id: 'b', label: 'BCA', value: 5000000),
        ],
        savings: const [
          AccountBalance(id: 's1', label: 'Tabungan', value: 20000000),
        ],
        cards: const [
          CardBalance(id: 'c1', label: 'BCA Card', limit: 10000000, used: 2500000),
          CardBalance(id: 'c2', label: 'Mandiri Card', limit: 5000000, used: 1000000),
        ],
      );
      expect(nw.cash, 5500000);
      expect(nw.savings, 20000000);
      expect(nw.debt, 3500000);
      expect(nw.assets, 25500000);
      expect(nw.total, 22000000);
    });

    test('total may be negative when debt exceeds assets', () {
      final nw = computeNetWorth(
        cash: const [AccountBalance(id: 'a', label: 'x', value: 1000)],
        savings: const [],
        cards: const [
          CardBalance(id: 'c', label: 'x', limit: 999999, used: 50000),
        ],
      );
      expect(nw.total, -49000);
    });
  });

  group('CardBalance.available', () {
    // Changed from the old `limit - used` rule: BCA blocks the full unpaid
    // cicilan remainder (`outstanding`) from the limit, so available uses
    // `outstanding`. When outstanding is omitted it defaults to `used`.
    test('limit - outstanding, clamped at 0', () {
      // outstanding > used: available drops below limit - used.
      expect(
        const CardBalance(
          id: 'c',
          label: 'x',
          limit: 25000000,
          used: 0,
          outstanding: 5260000,
        ).available,
        19740000,
      );
      // Over-limit (shouldn't happen but guard): clamp to 0.
      expect(
        const CardBalance(
          id: 'c',
          label: 'x',
          limit: 1000000,
          used: 0,
          outstanding: 1500000,
        ).available,
        0,
      );
    });

    test('outstanding defaults to used when omitted', () {
      expect(
        const CardBalance(id: 'c', label: 'x', limit: 1000000, used: 250000)
            .available,
        750000,
      );
    });
  });

  group('applyDelta', () {
    test('positive delta increases', () {
      expect(applyDelta(currentValue: 1000, delta: 500), 1500);
    });
    test('negative delta decreases', () {
      expect(applyDelta(currentValue: 1000, delta: -300), 700);
    });
    test('clamps at zero (no negative cash)', () {
      expect(applyDelta(currentValue: 100, delta: -500), 0);
    });
  });
}
