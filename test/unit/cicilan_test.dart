import 'package:financial_tracker/src/core/cicilan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeCicilan / flat', () {
    test('0% APR: total == principal, monthly = principal / months', () {
      final p = computeCicilan(principal: 6000000, months: 6, apr: 0);
      expect(p.total, 6000000);
      expect(p.totalInterest, 0);
      expect(p.monthly, 1000000);
    });

    test('1.5%/month flat (18% APR) over 12 months', () {
      // monthly interest rate = 0.18 / 12 = 0.015
      // total interest = 10_000_000 * 0.015 * 12 = 1_800_000
      // total = 11_800_000; monthly ≈ 983_333
      final p = computeCicilan(
        principal: 10000000,
        months: 12,
        apr: 0.18,
        model: InterestModel.flat,
      );
      expect(p.totalInterest, 1800000);
      expect(p.total, 11800000);
      expect(p.monthly, 983333);
    });

    test('rounds monthly correctly when not evenly divisible', () {
      final p = computeCicilan(principal: 1000001, months: 3, apr: 0);
      expect(p.monthly, 333334);
    });
  });

  group('computeCicilan / effective', () {
    test('matches standard amortising loan formula', () {
      // P=1_000_000, APR=12% (r=0.01/mo), n=12 → monthly ≈ 88,849
      final p = computeCicilan(
        principal: 1000000,
        months: 12,
        apr: 0.12,
        model: InterestModel.effective,
      );
      expect(p.monthly, inInclusiveRange(88800, 88900));
      expect(p.total, p.monthly * 12);
      expect(p.totalInterest, p.total - p.principal);
    });
  });

  group('computeCicilan / errors', () {
    test('throws on non-positive principal', () {
      expect(() => computeCicilan(principal: 0, months: 6, apr: 0),
          throwsArgumentError);
      expect(() => computeCicilan(principal: -1, months: 6, apr: 0),
          throwsArgumentError);
    });

    test('throws on months < 1', () {
      expect(() => computeCicilan(principal: 1000000, months: 0, apr: 0),
          throwsArgumentError);
    });

    test('throws on negative APR', () {
      expect(() => computeCicilan(principal: 1000000, months: 6, apr: -0.1),
          throwsArgumentError);
    });
  });

  group('minimumPayment', () {
    test('returns 0 for non-positive balance', () {
      expect(minimumPayment(balance: 0, minPaymentPct: 0.1), 0);
      expect(minimumPayment(balance: -1, minPaymentPct: 0.1), 0);
    });

    test('uses percentage when above floor', () {
      // 10% of 1_000_000 = 100_000 > 50_000 floor
      expect(minimumPayment(balance: 1000000, minPaymentPct: 0.10), 100000);
    });

    test('applies floor when percentage is below it', () {
      // 10% of 200_000 = 20_000 < 50_000 floor → 50_000
      expect(minimumPayment(balance: 200000, minPaymentPct: 0.10), 50000);
    });

    test('caps at outstanding balance', () {
      // floor 50_000 but balance is only 30_000 → return 30_000
      expect(minimumPayment(balance: 30000, minPaymentPct: 0.10), 30000);
    });
  });
}
