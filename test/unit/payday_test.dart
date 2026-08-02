import 'package:financial_tracker/src/core/payday.dart';
import 'package:flutter_test/flutter_test.dart';

void _paydayEdgeTests() {
  test('payday 1: rollback lintas bulan tidak menghasilkan siklus 0 hari', () {
    // 1 Agu 2026 = Sabtu → payday mundur ke Jumat 31 Jul. Pada 2 Agu,
    // start = 31 Jul; payday nominal 1 Sep (Selasa) jadi endExclusive.
    final c = currentCycle(DateTime(2026, 8, 2), payday: 1);
    expect(c.start, DateTime(2026, 7, 31));
    expect(c.endExclusive.isAfter(c.start), isTrue);
    expect(cycleLengthDays(c), greaterThan(0));
  });

  test('payday 2: 2 Agu 2026 (Minggu) rollback, siklus tetap valid', () {
    final c = currentCycle(DateTime(2026, 8, 2), payday: 2);
    expect(c.endExclusive.isAfter(c.start), isTrue);
  });
}

void main() {
  group('resolvePayday', () {
    test('returns the target day when it is a weekday', () {
      // 30 Sep 2025 is a Tuesday.
      final d = resolvePayday(2025, 9, 30);
      expect(d, DateTime(2025, 9, 30));
      expect(d.weekday, DateTime.tuesday);
    });

    test('rolls back from Saturday to Friday', () {
      // 30 Nov 2024 is a Saturday → rolls to Fri 29.
      final d = resolvePayday(2024, 11, 30);
      expect(d, DateTime(2024, 11, 29));
      expect(d.weekday, DateTime.friday);
    });

    test('rolls back from Sunday to Friday (skips Saturday too)', () {
      // 30 Mar 2025 is a Sunday → rolls back to Fri 28.
      final d = resolvePayday(2025, 3, 30);
      expect(d, DateTime(2025, 3, 28));
      expect(d.weekday, DateTime.friday);
    });

    test('clamps day past end of month (Feb)', () {
      // Feb 2025 has 28 days; 31 → 28.
      final d = resolvePayday(2025, 2, 31);
      expect(d, DateTime(2025, 2, 28));
    });

    test('clamps + rollback combined', () {
      // Feb 2026 last day is 28 (Saturday) → rolls back to Fri 27.
      final d = resolvePayday(2026, 2, 31);
      expect(d, DateTime(2026, 2, 27));
      expect(d.weekday, DateTime.friday);
    });
  });

  group('currentCycle', () {
    _paydayEdgeTests();

    test('uses this-month payday when now is on/after it', () {
      // Now = 5 Oct 2025; payday = 30. Sept 30 2025 = Tue → cycle starts Sept 30.
      final cycle = currentCycle(DateTime(2025, 10, 5), payday: 30);
      expect(cycle.start, DateTime(2025, 9, 30));
      expect(cycle.endExclusive, DateTime(2025, 10, 30));
    });

    test('rolls to previous month when now is before this-month payday', () {
      // Now = 25 Oct 2025; this-month payday Oct 30 (Thu, not yet) →
      // start = Sept 30.
      final cycle = currentCycle(DateTime(2025, 10, 25), payday: 30);
      expect(cycle.start, DateTime(2025, 9, 30));
      expect(cycle.endExclusive, DateTime(2025, 10, 30));
    });

    test('cycle spans weekend-adjusted paydays', () {
      // Now = 1 Dec 2024. Nov 30 2024 = Sat → start = Fri Nov 29.
      // Dec 30 2024 = Mon → endExclusive = Dec 30.
      final cycle = currentCycle(DateTime(2024, 12, 1), payday: 30);
      expect(cycle.start, DateTime(2024, 11, 29));
      expect(cycle.endExclusive, DateTime(2024, 12, 30));
    });

    test('cycleLengthDays returns correct day count', () {
      final cycle = currentCycle(DateTime(2025, 10, 5), payday: 30);
      expect(cycleLengthDays(cycle), 30);
    });
  });
}
