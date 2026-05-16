import 'package:financial_tracker/src/core/recurring.dart';
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
}
