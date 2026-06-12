import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/safe_to_spend.dart';

void main() {
  group('safeToSpend', () {
    test('sisa dibagi hari tersisa', () {
      final r = safeToSpend(
          totalBudget: 3000000, spent: 1000000, daysLeft: 10);
      expect(r.remaining, 2000000);
      expect(r.perDay, 200000);
    });

    test('hari terakhir: semua sisa boleh dipakai', () {
      final r =
          safeToSpend(totalBudget: 1000000, spent: 900000, daysLeft: 1);
      expect(r.perDay, 100000);
    });

    test('over budget: perDay 0, remaining negatif', () {
      final r =
          safeToSpend(totalBudget: 1000000, spent: 1200000, daysLeft: 5);
      expect(r.perDay, 0);
      expect(r.remaining, -200000);
    });

    test('daysLeft 0 tidak membagi nol', () {
      final r =
          safeToSpend(totalBudget: 1000000, spent: 0, daysLeft: 0);
      expect(r.perDay, 1000000);
    });
  });
}
