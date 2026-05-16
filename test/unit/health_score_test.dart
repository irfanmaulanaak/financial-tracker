import 'package:financial_tracker/src/core/health_score.dart';
import 'package:flutter_test/flutter_test.dart';

HealthScoreInputs _i({
  int spend = 0,
  int income = 0,
  int budget = 0,
  int savings = 0,
  int debt = 0,
  int avgSpend = 0,
  int invest = 0,
}) =>
    HealthScoreInputs(
      spendThisCycle: spend,
      incomeThisCycle: income,
      monthlyBudget: budget,
      savingsBalance: savings,
      cardDebt: debt,
      avgMonthlySpend: avgSpend,
      investmentCount: invest,
    );

void main() {
  group('computeHealthScore', () {
    test('all zero inputs → score = 0 (only investasi has data)', () {
      final r = computeHealthScore(_i());
      // Only investasi factor has data (it doesn't require any input gate).
      expect(r.score, 0);
      expect(r.verdict, 'Kritis');
    });

    test('perfect-everything → 100', () {
      final r = computeHealthScore(_i(
        spend: 0,
        income: 10000000,
        budget: 9000000,
        savings: 60000000,
        debt: 0,
        avgSpend: 10000000,
        invest: 5,
      ));
      expect(r.score, 100);
      expect(r.verdict, 'Sangat sehat');
    });

    test('factor missing → weight is redistributed', () {
      // No income data → "menabung" + "utang" skipped. Remaining factors
      // (disiplin 30, darurat 20, investasi 10) cover 100% pro-rata.
      final r = computeHealthScore(_i(
        spend: 0,
        income: 0,
        budget: 5000000,
        savings: 60000000,
        avgSpend: 5000000,
        invest: 5,
      ));
      expect(r.factors.firstWhere((f) => f.key == 'menabung').contribution,
          isNull);
      expect(r.factors.firstWhere((f) => f.key == 'utang').contribution,
          isNull);
      // Disiplin 30/60 ≈ 50, darurat 20/60 ≈ 33.3, investasi 10/60 ≈ 16.7
      // All at 100% → sum = 100.
      expect(r.score, 100);
    });

    test('budget blown → disiplin = 0', () {
      final r = computeHealthScore(_i(
        spend: 10000000,
        income: 10000000,
        budget: 5000000,
        savings: 0,
        avgSpend: 5000000,
        invest: 0,
      ));
      final disiplin = r.factors.firstWhere((f) => f.key == 'disiplin');
      expect(disiplin.rawScore01, 0);
      expect(disiplin.contribution, 0);
    });

    test('partial savings rate computed correctly', () {
      // spend = 6jt, income = 10jt → saved 4jt → rate = 0.4
      // menabung weight = 25 → contrib ≈ 10
      final r = computeHealthScore(_i(
        spend: 6000000,
        income: 10000000,
        budget: 999999999,
        savings: 0,
        avgSpend: 6000000,
        invest: 0,
      ));
      final menabung = r.factors.firstWhere((f) => f.key == 'menabung');
      expect(menabung.rawScore01, closeTo(0.4, 0.001));
      expect(menabung.contribution, closeTo(10, 1));
    });

    test('verdict bands', () {
      expect(verdictFor(95), 'Sangat sehat');
      expect(verdictFor(80), 'Sangat sehat');
      expect(verdictFor(79), 'Sehat');
      expect(verdictFor(65), 'Sehat');
      expect(verdictFor(50), 'Cukup');
      expect(verdictFor(49), 'Perlu perbaikan');
      expect(verdictFor(30), 'Perlu perbaikan');
      expect(verdictFor(29), 'Kritis');
      expect(verdictFor(0), 'Kritis');
    });

    test('debt > 6x income → utang factor = 0', () {
      final r = computeHealthScore(_i(
        income: 1000000,
        debt: 100000000, // 100x monthly income
      ));
      final utang = r.factors.firstWhere((f) => f.key == 'utang');
      expect(utang.rawScore01, 0);
    });

    test('investments > 5 still clamps to 1.0 (max contrib = 10)', () {
      final r = computeHealthScore(_i(invest: 20));
      final inv = r.factors.firstWhere((f) => f.key == 'investasi');
      expect(inv.rawScore01, 1.0);
    });
  });
}
