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
}
