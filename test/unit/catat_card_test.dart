import 'package:financial_tracker/src/core/catat_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catatCardAmounts', () {
    test('under budget → counts down the remaining amount', () {
      final a = catatCardAmounts(
        budget: 2500000,
        spentBeforeSave: 1567994,
        amount: 56300,
      );
      expect(a.over, isFalse);
      expect(a.oldValue, 932006);
      expect(a.newValue, 875706);
    });

    test('crossing into over budget this save → old=0, new=the over amount', () {
      final a = catatCardAmounts(
        budget: 5000000,
        spentBeforeSave: 4900000,
        amount: 150000,
      );
      expect(a.over, isTrue);
      expect(a.oldValue, 0);
      expect(a.newValue, 50000);
    });

    test('already over budget before this save → old is the prior over amount', () {
      final a = catatCardAmounts(
        budget: 5000000,
        spentBeforeSave: 6060605,
        amount: 150000,
      );
      expect(a.over, isTrue);
      expect(a.oldValue, 1060605);
      expect(a.newValue, 1210605);
    });

    test('exactly at budget → not over', () {
      final a = catatCardAmounts(
        budget: 1000000,
        spentBeforeSave: 900000,
        amount: 100000,
      );
      expect(a.over, isFalse);
      expect(a.newValue, 0);
    });
  });

  group('catatCardEligible', () {
    final cycleStart = DateTime(2026, 9, 30);
    final cycleEnd = DateTime(2026, 10, 30);

    test('no budget on the category → not eligible', () {
      expect(
        catatCardEligible(
          monthlyBudget: 0,
          date: DateTime(2026, 10, 5),
          cycleStart: cycleStart,
          cycleEndExclusive: cycleEnd,
        ),
        isFalse,
      );
    });

    test('date before the cycle start → not eligible', () {
      expect(
        catatCardEligible(
          monthlyBudget: 2500000,
          date: DateTime(2026, 9, 29),
          cycleStart: cycleStart,
          cycleEndExclusive: cycleEnd,
        ),
        isFalse,
      );
    });

    test('date on/after the cycle end → not eligible', () {
      expect(
        catatCardEligible(
          monthlyBudget: 2500000,
          date: DateTime(2026, 10, 30),
          cycleStart: cycleStart,
          cycleEndExclusive: cycleEnd,
        ),
        isFalse,
      );
    });

    test('budgeted category, date inside the cycle → eligible', () {
      expect(
        catatCardEligible(
          monthlyBudget: 2500000,
          date: DateTime(2026, 10, 5),
          cycleStart: cycleStart,
          cycleEndExclusive: cycleEnd,
        ),
        isTrue,
      );
    });
  });
}
