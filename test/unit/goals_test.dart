import 'package:financial_tracker/src/features/goals/goal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('goalMilestoneCrossed', () {
    test('melewati 50% → 50', () {
      expect(
        goalMilestoneCrossed(before: 400, after: 500, target: 1000),
        50,
      );
      expect(
        goalMilestoneCrossed(before: 499, after: 999, target: 1000),
        50,
      );
    });

    test('melewati 100% → 100 (prioritas di atas 50)', () {
      expect(
        goalMilestoneCrossed(before: 900, after: 1000, target: 1000),
        100,
      );
      expect(
        goalMilestoneCrossed(before: 100, after: 1500, target: 1000),
        100,
      );
    });

    test('tidak melewati apa-apa → null', () {
      expect(
        goalMilestoneCrossed(before: 500, after: 600, target: 1000),
        isNull,
      );
      expect(
        goalMilestoneCrossed(before: 0, after: 499, target: 1000),
        isNull,
      );
    });

    test('sudah lewat sebelumnya → tidak dirayakan ulang', () {
      expect(
        goalMilestoneCrossed(before: 1000, after: 1100, target: 1000),
        isNull,
      );
      expect(
        goalMilestoneCrossed(before: 500, after: 700, target: 1000),
        isNull,
      );
    });

    test('target nol / setoran mundur → null', () {
      expect(goalMilestoneCrossed(before: 0, after: 10, target: 0), isNull);
      expect(
        goalMilestoneCrossed(before: 600, after: 500, target: 1000),
        isNull,
      );
    });
  });

  group('reorderIds', () {
    const ids = ['a', 'b', 'c', 'd'];

    test('moving down applies the ReorderableListView -1 fix-up', () {
      // Drag 'a' below 'c': Flutter reports newIndex 3 (pre-removal).
      expect(
        reorderIds(ids: ids, oldIndex: 0, newIndex: 3),
        ['b', 'c', 'a', 'd'],
      );
    });

    test('moving up inserts at the reported index', () {
      expect(
        reorderIds(ids: ids, oldIndex: 3, newIndex: 1),
        ['a', 'd', 'b', 'c'],
      );
    });

    test('dropping in place is a no-op', () {
      expect(reorderIds(ids: ids, oldIndex: 2, newIndex: 2), ids);
      // Dropping one slot below itself (newIndex = old + 1) is also a no-op
      // after the fix-up.
      expect(reorderIds(ids: ids, oldIndex: 2, newIndex: 3), ids);
    });
  });

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
