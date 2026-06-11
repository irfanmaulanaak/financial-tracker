import 'package:financial_tracker/src/features/home/net_worth_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('snapshotDocId', () {
    test('formats YYYY-MM-DD with zero padding', () {
      expect(snapshotDocId(DateTime(2026, 1, 5)), '2026-01-05');
      expect(snapshotDocId(DateTime(2026, 12, 31)), '2026-12-31');
      expect(snapshotDocId(DateTime(999, 9, 9)), '0999-09-09');
    });

    test('ignores time-of-day — same date always produces same id', () {
      final a = snapshotDocId(DateTime(2026, 5, 17, 0, 0));
      final b = snapshotDocId(DateTime(2026, 5, 17, 23, 59, 59));
      expect(a, b);
    });
  });

  group('localMidnight', () {
    test('drops time portion', () {
      final m = localMidnight(DateTime(2026, 5, 17, 14, 30, 12));
      expect(m, DateTime(2026, 5, 17));
    });
  });

  group('fillDailyNetWorthSeries', () {
    NetWorthSnapshot snap(DateTime date, int total) => NetWorthSnapshot(
          date: date,
          cash: 0,
          savings: 0,
          investments: 0,
          debt: 0,
          total: total,
          capturedBy: 'u',
        );

    final today = DateTime(2026, 6, 11);

    test('empty input → empty output', () {
      expect(fillDailyNetWorthSeries(const [], now: today), isEmpty);
    });

    test('gap days carry the last known total forward', () {
      // Snapshots on 8 and 11 Jun only; 9-10 Jun were not opened.
      final out = fillDailyNetWorthSeries(
        [snap(DateTime(2026, 6, 8), 100), snap(DateTime(2026, 6, 11), 130)],
        days: 5,
        now: today,
      );
      expect(out.map((p) => p.date.day), [8, 9, 10, 11]);
      expect(out.map((p) => p.total), [100, 100, 100, 130]);
    });

    test('days before the first snapshot are omitted', () {
      final out = fillDailyNetWorthSeries(
        [snap(DateTime(2026, 6, 10), 50)],
        days: 14,
        now: today,
      );
      expect(out.length, 2); // 10 + 11 Jun only
      expect(out.first.date, DateTime(2026, 6, 10));
      expect(out.last.total, 50);
    });

    test('snapshot older than the window primes the carry-forward', () {
      final out = fillDailyNetWorthSeries(
        [snap(DateTime(2026, 5, 1), 75)],
        days: 7,
        now: today,
      );
      expect(out.length, 7); // full window, all carried from 1 Mei
      expect(out.every((p) => p.total == 75), isTrue);
    });

    test('one point per day, oldest first, ends today', () {
      final out = fillDailyNetWorthSeries(
        [for (var d = 1; d <= 11; d++) snap(DateTime(2026, 6, d), d * 10)],
        days: 7,
        now: today,
      );
      expect(out.length, 7);
      expect(out.first.date, DateTime(2026, 6, 5));
      expect(out.last.date, today);
      expect(out.last.total, 110);
    });
  });
}
