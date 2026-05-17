import 'package:financial_tracker/src/core/in_app_indicators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('budgetStatus', () {
    test('no budget → ok', () {
      expect(budgetStatus(totalSpent: 10000, monthlyBudget: 0),
          BudgetStatus.ok);
    });
    test('< 80% → ok', () {
      expect(budgetStatus(totalSpent: 79, monthlyBudget: 100),
          BudgetStatus.ok);
    });
    test('exactly 80% → warning', () {
      expect(budgetStatus(totalSpent: 80, monthlyBudget: 100),
          BudgetStatus.warning);
    });
    test('99% → warning', () {
      expect(budgetStatus(totalSpent: 99, monthlyBudget: 100),
          BudgetStatus.warning);
    });
    test('exactly at budget → exceeded', () {
      expect(budgetStatus(totalSpent: 100, monthlyBudget: 100),
          BudgetStatus.exceeded);
    });
    test('over → exceeded', () {
      expect(budgetStatus(totalSpent: 150, monthlyBudget: 100),
          BudgetStatus.exceeded);
    });
  });

  group('daysUntilDue', () {
    test('due date 5 days away → 5', () {
      expect(
          daysUntilDue(dueDay: 20, now: DateTime(2025, 10, 15)), 5);
    });

    test('due date 6 days away → null (outside warn window)', () {
      expect(
          daysUntilDue(dueDay: 21, now: DateTime(2025, 10, 15)), null);
    });

    test('today is due day → 0', () {
      expect(
          daysUntilDue(dueDay: 15, now: DateTime(2025, 10, 15)), 0);
    });

    test('due day already passed this month → rolls to next month', () {
      // Today: 28 Oct. Due day 10 → next is 10 Nov → 13 days. Outside default
      // 5-day warn window so we widen it.
      final d = daysUntilDue(
        dueDay: 10,
        now: DateTime(2025, 10, 28),
        warnWithinDays: 20,
      );
      expect(d, 13);
    });

    test('due day 31 in February → clamps to last day of feb', () {
      // 28 days in Feb 2025
      // Today: 24 Feb. Due 31 → clamped to 28 Feb → 4 days away.
      final d = daysUntilDue(dueDay: 31, now: DateTime(2025, 2, 24));
      expect(d, 4);
    });
  });

  group('isInvestmentStale', () {
    test('fresh (0 days) → not stale', () {
      expect(
        isInvestmentStale(
          updatedAt: DateTime(2025, 10, 15),
          now: DateTime(2025, 10, 15),
          currentValue: 1_000_000,
        ),
        false,
      );
    });

    test('6 days old → not stale (just under threshold)', () {
      expect(
        isInvestmentStale(
          updatedAt: DateTime(2025, 10, 15),
          now: DateTime(2025, 10, 21),
          currentValue: 1_000_000,
        ),
        false,
      );
    });

    test('exactly 7 days old → stale', () {
      expect(
        isInvestmentStale(
          updatedAt: DateTime(2025, 10, 15),
          now: DateTime(2025, 10, 22),
          currentValue: 1_000_000,
        ),
        true,
      );
    });

    test('30 days old → stale', () {
      expect(
        isInvestmentStale(
          updatedAt: DateTime(2025, 10, 1),
          now: DateTime(2025, 10, 31),
          currentValue: 1_000_000,
        ),
        true,
      );
    });

    test('zero currentValue → never stale (dormant position)', () {
      expect(
        isInvestmentStale(
          updatedAt: DateTime(2024, 1, 1),
          now: DateTime(2025, 10, 22),
          currentValue: 0,
        ),
        false,
      );
    });

    test('custom threshold honoured', () {
      expect(
        isInvestmentStale(
          updatedAt: DateTime(2025, 10, 15),
          now: DateTime(2025, 10, 22),
          currentValue: 1_000_000,
          staleAfterDays: 14,
        ),
        false,
      );
      expect(
        isInvestmentStale(
          updatedAt: DateTime(2025, 10, 1),
          now: DateTime(2025, 10, 22),
          currentValue: 1_000_000,
          staleAfterDays: 14,
        ),
        true,
      );
    });
  });
}
