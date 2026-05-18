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

  group('computeMonthsBilled', () {
    test('returns 0 before first billing date (start day > billingDay)', () {
      // Bought May 16, billing day 12 → first billing = June 12.
      // Today May 18 → no billing yet.
      expect(
        computeMonthsBilled(
          startedAt: DateTime(2026, 5, 16),
          today: DateTime(2026, 5, 18),
          billingDay: 12,
        ),
        0,
      );
    });

    test('returns 0 when today is before billingDay in same month', () {
      // Bought May 5 (before billing day), billing day 12.
      // Today May 10 → first billing still upcoming May 12.
      expect(
        computeMonthsBilled(
          startedAt: DateTime(2026, 5, 5),
          today: DateTime(2026, 5, 10),
          billingDay: 12,
        ),
        0,
      );
    });

    test('counts same-month billing when start.day == billingDay', () {
      // Bought May 12 (== billing day), today May 12.
      expect(
        computeMonthsBilled(
          startedAt: DateTime(2026, 5, 12),
          today: DateTime(2026, 5, 12),
          billingDay: 12,
        ),
        1,
      );
    });

    test('counts subsequent monthly crossings', () {
      // Bought March 15 (> billing 12), so first crossing April 12.
      // Today May 18 → April 12 + May 12 = 2.
      expect(
        computeMonthsBilled(
          startedAt: DateTime(2026, 3, 15),
          today: DateTime(2026, 5, 18),
          billingDay: 12,
        ),
        2,
      );
    });

    test('clamps billingDay to short month length', () {
      // Bought Jan 5 (≤ billing 30), so first crossing Jan 30.
      // Feb has no 30 → clamp to Feb 28 (2026 is not leap).
      // Today Mar 1 → Jan 30 + Feb 28 = 2.
      expect(
        computeMonthsBilled(
          startedAt: DateTime(2026, 1, 5),
          today: DateTime(2026, 3, 1),
          billingDay: 30,
        ),
        2,
      );
    });

    test('future startedAt returns 0', () {
      expect(
        computeMonthsBilled(
          startedAt: DateTime(2026, 12, 1),
          today: DateTime(2026, 5, 18),
          billingDay: 12,
        ),
        0,
      );
    });
  });

  group('cicilanBlocked', () {
    test('full principal when monthsBilled == 0 (just-approved cicilan)', () {
      // Bought May 16, today May 18, billing 12 → monthsBilled=0.
      // 3-month plan, 0 paid, monthly 433_000.
      expect(
        cicilanBlocked(
          monthsTotal: 3,
          monthsPaid: 0,
          monthly: 433000,
          startedAt: DateTime(2026, 5, 16),
          today: DateTime(2026, 5, 18),
          billingDay: 12,
        ),
        3 * 433000,
      );
    });

    test('blocked drops to monthly × unpaid-billed once billing crossed', () {
      // Bought March 15, today May 18, billing 12 → monthsBilled=2.
      // 3-month plan, 1 paid, monthly 3_663_333.
      // (2-1) * 3_663_333 = 3_663_333.
      expect(
        cicilanBlocked(
          monthsTotal: 3,
          monthsPaid: 1,
          monthly: 3663333,
          startedAt: DateTime(2026, 3, 15),
          today: DateTime(2026, 5, 18),
          billingDay: 12,
        ),
        3663333,
      );
    });

    test('returns 0 once monthsPaid catches monthsBilled', () {
      expect(
        cicilanBlocked(
          monthsTotal: 3,
          monthsPaid: 2,
          monthly: 3663333,
          startedAt: DateTime(2026, 3, 15),
          today: DateTime(2026, 5, 18),
          billingDay: 12,
        ),
        0,
      );
    });

    test('returns 0 when cicilan is fully paid', () {
      expect(
        cicilanBlocked(
          monthsTotal: 3,
          monthsPaid: 3,
          monthly: 1000000,
          startedAt: DateTime(2026, 1, 1),
          today: DateTime(2026, 6, 1),
          billingDay: 12,
        ),
        0,
      );
    });

    test('caps monthsBilled at monthsTotal for overdue cicilan', () {
      // 3-month plan started Jan 2025, today June 2026: many billings passed
      // but only 3 installments exist. Unpaid: monthsTotal-monthsPaid=3.
      expect(
        cicilanBlocked(
          monthsTotal: 3,
          monthsPaid: 0,
          monthly: 1000000,
          startedAt: DateTime(2025, 1, 1),
          today: DateTime(2026, 6, 1),
          billingDay: 12,
        ),
        3000000,
      );
    });

    test('reconstructs BCA screenshot: total blocked == 9_775_392 + plain', () {
      // Real numbers from user's BCA snapshot:
      // - coach wifey: 1/3 paid, monthly 3_663_333, started Mar (any day < May 12)
      // - vga: 1/3 paid, monthly 3_562_860, started Mar (same)
      // - sepatu puma: 0/3 paid, monthly 433_000, started May 16 (after 12)
      // - shopee walking pad: 0/3 paid, monthly 516_733, started May 17 (after 12)
      // Today = May 18, billing day 12.
      final today = DateTime(2026, 5, 18);
      const billing = 12;
      final coach = cicilanBlocked(
        monthsTotal: 3,
        monthsPaid: 1,
        monthly: 3663333,
        startedAt: DateTime(2026, 3, 15),
        today: today,
        billingDay: billing,
      );
      final vga = cicilanBlocked(
        monthsTotal: 3,
        monthsPaid: 1,
        monthly: 3562860,
        startedAt: DateTime(2026, 3, 15),
        today: today,
        billingDay: billing,
      );
      final puma = cicilanBlocked(
        monthsTotal: 3,
        monthsPaid: 0,
        monthly: 433000,
        startedAt: DateTime(2026, 5, 16),
        today: today,
        billingDay: billing,
      );
      final walkingPad = cicilanBlocked(
        monthsTotal: 3,
        monthsPaid: 0,
        monthly: 516733,
        startedAt: DateTime(2026, 5, 17),
        today: today,
        billingDay: billing,
      );
      // 3_663_333 + 3_562_860 + (3 * 433_000) + (3 * 516_733)
      // = 7_226_193 + 1_299_000 + 1_550_199 = 10_075_392
      expect(coach + vga + puma + walkingPad, 10075392);
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
