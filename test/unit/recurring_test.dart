import 'package:financial_tracker/src/core/recurring.dart';
import 'package:financial_tracker/src/core/recurring_runner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('datesToMaterialise', () {
    test('lastSeen ≥ now → empty', () {
      final d = DateTime(2025, 10, 1);
      expect(datesToMaterialise(lastSeen: d, now: d), isEmpty);
      expect(
          datesToMaterialise(lastSeen: d, now: d.subtract(const Duration(days: 1))),
          isEmpty);
    });

    test('one month gap → 1 new date', () {
      final out = datesToMaterialise(
        lastSeen: DateTime(2025, 1, 15),
        now: DateTime(2025, 2, 15),
      );
      expect(out.length, 1);
      expect(out.first, DateTime(2025, 2, 15));
    });

    test('half-month gap → empty (need a full month)', () {
      final out = datesToMaterialise(
        lastSeen: DateTime(2025, 1, 15),
        now: DateTime(2025, 2, 10),
      );
      expect(out, isEmpty);
    });

    test('three full months → 3 dates', () {
      final out = datesToMaterialise(
        lastSeen: DateTime(2025, 1, 10),
        now: DateTime(2025, 4, 12),
      );
      expect(out, [
        DateTime(2025, 2, 10),
        DateTime(2025, 3, 10),
        DateTime(2025, 4, 10),
      ]);
    });

    test('day clamps when month is shorter (jan 31 → feb 28)', () {
      final out = datesToMaterialise(
        lastSeen: DateTime(2025, 1, 31),
        now: DateTime(2025, 3, 31),
      );
      // Feb 28 + March 31
      expect(out, [DateTime(2025, 2, 28), DateTime(2025, 3, 28)]);
    });

    test('crosses year boundary', () {
      final out = datesToMaterialise(
        lastSeen: DateTime(2024, 12, 1),
        now: DateTime(2025, 2, 1),
      );
      expect(out, [DateTime(2025, 1, 1), DateTime(2025, 2, 1)]);
    });
  });

  group('latestPerKey', () {
    test('picks most recent per key, skips non-recurring', () {
      final items = [
        (key: 'rent', date: DateTime(2025, 1, 1), rec: true),
        (key: 'rent', date: DateTime(2025, 3, 1), rec: true),
        (key: 'rent', date: DateTime(2025, 2, 1), rec: true),
        (key: 'snacks', date: DateTime(2025, 5, 1), rec: false),
      ];
      final out = latestPerKey<({String key, DateTime date, bool rec})>(
        items,
        keyOf: (e) => e.key,
        dateOf: (e) => e.date,
        isRecurring: (e) => e.rec,
      );
      expect(out.length, 1);
      expect(out['rent'], DateTime(2025, 3, 1));
    });
  });

  group('recurringDocId', () {
    test('stable across calls with the same input', () {
      final id1 = recurringDocId('rent|cash1|1500000||', DateTime(2025, 5, 1));
      final id2 = recurringDocId('rent|cash1|1500000||', DateTime(2025, 5, 1));
      expect(id1, id2);
    });

    test('different date → different id', () {
      final id1 = recurringDocId('rent|cash1|1500000||', DateTime(2025, 5, 1));
      final id2 = recurringDocId('rent|cash1|1500000||', DateTime(2025, 6, 1));
      expect(id1, isNot(id2));
    });

    test('different template key → different id', () {
      final id1 = recurringDocId('rent|cash1|1500000||', DateTime(2025, 5, 1));
      final id2 = recurringDocId('rent|cash1|2000000||', DateTime(2025, 5, 1));
      expect(id1, isNot(id2));
    });

    test('format matches recur_<hex>_<yyyymmdd>', () {
      final id = recurringDocId('x', DateTime(2026, 3, 7));
      expect(id, matches(RegExp(r'^recur_[0-9a-f]{8}_20260307$')));
    });
  });
}
