import 'package:financial_tracker/src/features/goals/goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Goal helpers', () {
    test('progress clamped 0..1', () {
      final g = Goal(
        id: 'g1',
        label: 'Dana darurat',
        target: 1000,
        current: 200,
        dueDate: null,
        monthlyContrib: 100,
        icon: 'savings',
        color: '#10B981',
        scope: GoalScope.shared,
        ownerId: null,
        createdAt: DateTime(2025),
      );
      expect(g.progress, closeTo(0.2, 0.0001));
      expect(g.remaining, 800);
      expect(g.isComplete, isFalse);
    });

    test('over-target → isComplete + progress = 1', () {
      final g = Goal(
        id: 'g1',
        label: '',
        target: 1000,
        current: 1500,
        dueDate: null,
        monthlyContrib: 0,
        icon: '',
        color: '',
        scope: GoalScope.shared,
        ownerId: null,
        createdAt: DateTime(2025),
      );
      expect(g.isComplete, isTrue);
      expect(g.progress, 1.0);
      expect(g.remaining, 0);
    });
  });

  group('monthsToGoal', () {
    test('already met → 0', () {
      expect(
          monthsToGoal(target: 1000, current: 1500, monthlyContrib: 100), 0);
    });
    test('no contribution → null (unbounded)', () {
      expect(monthsToGoal(target: 1000, current: 100, monthlyContrib: 0),
          isNull);
    });
    test('exact division', () {
      expect(monthsToGoal(target: 1000, current: 0, monthlyContrib: 250), 4);
    });
    test('rounds up partial months', () {
      expect(monthsToGoal(target: 1000, current: 0, monthlyContrib: 300), 4);
    });
  });

  group('requiredMonthlyContribution', () {
    test('no due date → 0', () {
      expect(
          requiredMonthlyContribution(
              target: 1000,
              current: 0,
              dueDate: null,
              today: DateTime(2025, 1)),
          0);
    });
    test('already met → 0', () {
      expect(
          requiredMonthlyContribution(
              target: 1000,
              current: 1000,
              dueDate: DateTime(2025, 12),
              today: DateTime(2025, 1)),
          0);
    });
    test('12 months → remaining / 12', () {
      expect(
          requiredMonthlyContribution(
              target: 1_200_000,
              current: 0,
              dueDate: DateTime(2026, 1),
              today: DateTime(2025, 1)),
          100000);
    });
    test('rounds up so target is met', () {
      expect(
          requiredMonthlyContribution(
              target: 100,
              current: 0,
              dueDate: DateTime(2025, 4),
              today: DateTime(2025, 1)),
          34); // 100/3 = 33.33 → 34
    });
  });
}
