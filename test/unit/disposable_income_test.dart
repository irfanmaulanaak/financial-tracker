import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/disposable_income.dart';

void main() {
  group('debtServiceSummary', () {
    test('skenario Irfan: KPR 3.5jt + mobil 2.5jt + CC 2.228jt / gaji 42jt', () {
      final r = debtServiceSummary(
        stableSalary: 42_050_000,
        fixedObligationsMonthly: 3_500_000 + 2_500_000,
        multiMonthCardMonthly: 2_228_000,
      );
      expect(r.totalMonthlyDebt, 8_228_000);
      expect(r.dsr, closeTo(0.196, 0.001));
      expect(r.dsr < dsrMaxOjk, isTrue);
      expect(r.disposable, 42_050_000 - 8_228_000);
    });

    test('gaji 0: dsr 0, disposable 0 (tanpa bagi nol)', () {
      final r = debtServiceSummary(
        stableSalary: 0,
        fixedObligationsMonthly: 1_000_000,
        multiMonthCardMonthly: 0,
      );
      expect(r.dsr, 0.0);
      expect(r.disposable, 0);
    });

    test('cicilan > gaji: disposable clamp 0, dsr > batas OJK', () {
      final r = debtServiceSummary(
        stableSalary: 5_000_000,
        fixedObligationsMonthly: 6_000_000,
        multiMonthCardMonthly: 0,
      );
      expect(r.disposable, 0);
      expect(r.dsr > dsrMaxOjk, isTrue);
    });
  });

  group('budgetOvercommit', () {
    test('budget 40jt vs disposable 37jt: over 3jt', () {
      expect(
        budgetOvercommit(monthlyBudgetTotal: 40_000_000, disposable: 37_000_000),
        3_000_000,
      );
    });

    test('budget di bawah disposable: 0', () {
      expect(
        budgetOvercommit(monthlyBudgetTotal: 20_000_000, disposable: 37_000_000),
        0,
      );
    });
  });
}
