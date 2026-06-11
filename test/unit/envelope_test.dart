import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/envelope.dart';

void main() {
  group('carryOver', () {
    test('leftover rolls over', () {
      expect(carryOver(monthlyBudget: 1000000, prevCycleSpent: 600000),
          400000);
    });

    test('overspend never goes negative', () {
      expect(carryOver(monthlyBudget: 1000000, prevCycleSpent: 1500000), 0);
    });

    test('no budget → no carry', () {
      expect(carryOver(monthlyBudget: 0, prevCycleSpent: 0), 0);
    });

    test('untouched envelope carries the full budget', () {
      expect(carryOver(monthlyBudget: 500000, prevCycleSpent: 0), 500000);
    });
  });

  group('effectiveBudget', () {
    test('rollover off → plain budget', () {
      expect(
        effectiveBudget(
            monthlyBudget: 1000000, rollover: false, prevCycleSpent: 0),
        1000000,
      );
    });

    test('rollover on adds carry', () {
      expect(
        effectiveBudget(
            monthlyBudget: 1000000, rollover: true, prevCycleSpent: 750000),
        1250000,
      );
    });

    test('rollover with overspend = plain budget (no debt carry)', () {
      expect(
        effectiveBudget(
            monthlyBudget: 1000000, rollover: true, prevCycleSpent: 2000000),
        1000000,
      );
    });
  });

  group('envelopeLeft', () {
    test('remaining envelope', () {
      expect(
        envelopeLeft(
          monthlyBudget: 1000000,
          rollover: true,
          prevCycleSpent: 800000,
          spentThisCycle: 300000,
        ),
        900000,
      );
    });

    test('floored at zero', () {
      expect(
        envelopeLeft(
          monthlyBudget: 100000,
          rollover: false,
          prevCycleSpent: 0,
          spentThisCycle: 250000,
        ),
        0,
      );
    });
  });
}
