import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/cash_projection.dart';

void main() {
  group('projectEndOfCycle', () {
    test('proyeksi = kas - tagihan - (rata harian x sisa hari)', () {
      final p = projectEndOfCycle(
        liquidNow: 10000000,
        upcomingBillsTotal: 2000000,
        variableSpentSoFar: 1500000,
        daysElapsed: 15,
        daysLeft: 10,
      );
      expect(p.estVariable, 100000 * 10);
      expect(p.projected, 10000000 - 2000000 - 1000000);
    });

    test('daysElapsed 0 tidak membagi nol', () {
      final p = projectEndOfCycle(
        liquidNow: 5000000,
        upcomingBillsTotal: 0,
        variableSpentSoFar: 0,
        daysElapsed: 0,
        daysLeft: 30,
      );
      expect(p.estVariable, 0);
      expect(p.projected, 5000000);
    });

    test('daysLeft negatif diperlakukan 0', () {
      final p = projectEndOfCycle(
        liquidNow: 1000,
        upcomingBillsTotal: 0,
        variableSpentSoFar: 999,
        daysElapsed: 30,
        daysLeft: -1,
      );
      expect(p.estVariable, 0);
    });

    test('bisa minus saat tagihan melebihi kas', () {
      final p = projectEndOfCycle(
        liquidNow: 1000000,
        upcomingBillsTotal: 1500000,
        variableSpentSoFar: 0,
        daysElapsed: 1,
        daysLeft: 5,
      );
      expect(p.projected, -500000);
    });
  });
}
