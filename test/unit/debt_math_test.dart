import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/debt_math.dart';

void main() {
  group('applyDebtPayment', () {
    test('partial payment accumulates', () {
      final r = applyDebtPayment(amount: 1000000, paid: 200000, payment: 300000);
      expect(r.paid, 500000);
      expect(r.settled, false);
    });

    test('payment clamps at amount and settles', () {
      final r = applyDebtPayment(amount: 1000000, paid: 900000, payment: 500000);
      expect(r.paid, 1000000);
      expect(r.settled, true);
    });

    test('exact payoff settles', () {
      final r = applyDebtPayment(amount: 500000, paid: 0, payment: 500000);
      expect(r.settled, true);
    });

    test('negative correction floors at zero', () {
      final r = applyDebtPayment(amount: 500000, paid: 100000, payment: -200000);
      expect(r.paid, 0);
      expect(r.settled, false);
    });
  });

  group('debtRemaining', () {
    test('remaining', () {
      expect(debtRemaining(amount: 1000000, paid: 250000), 750000);
    });
    test('never negative', () {
      expect(debtRemaining(amount: 100, paid: 500), 0);
    });
  });
}
