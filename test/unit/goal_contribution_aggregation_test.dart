import 'package:financial_tracker/src/features/goals/contribution.dart';
import 'package:flutter_test/flutter_test.dart';

GoalContribution _c(int amount, DateTime at) => GoalContribution(
      id: 'x',
      amount: amount,
      at: at,
      byUid: 'u',
      source: GoalContributionSource.manual,
    );

void main() {
  group('contributionsByMonth', () {
    test('empty input → all zeros, length matches monthsBack', () {
      final out = contributionsByMonth(
        contribs: const [],
        monthsBack: 8,
        now: DateTime(2026, 5, 17),
      );
      expect(out.length, 8);
      expect(out.every((v) => v == 0), isTrue);
    });

    test('buckets contributions into the correct month index', () {
      // Last bar = May 2026; 8 months back goes through Oct 2025.
      final now = DateTime(2026, 5, 17);
      final out = contributionsByMonth(
        contribs: [
          _c(100, DateTime(2026, 5, 1)),  // last bar
          _c(50, DateTime(2026, 5, 28)),  // last bar (sums)
          _c(200, DateTime(2026, 4, 15)), // 7th bar (idx 6)
          _c(300, DateTime(2025, 10, 5)), // first bar (idx 0)
        ],
        monthsBack: 8,
        now: now,
      );
      expect(out.last, 150);
      expect(out[6], 200);
      expect(out.first, 300);
      expect(out.where((v) => v != 0).length, 3);
    });

    test('crosses year boundary correctly (Jan 2026 → Dec 2025)', () {
      final now = DateTime(2026, 1, 15);
      final out = contributionsByMonth(
        contribs: [
          _c(70, DateTime(2025, 12, 28)),
          _c(40, DateTime(2026, 1, 5)),
        ],
        monthsBack: 4,
        now: now,
      );
      // Bars: Oct, Nov, Dec, Jan → indices 0, 1, 2, 3.
      expect(out, [0, 0, 70, 40]);
    });

    test('drops contributions outside the window', () {
      final now = DateTime(2026, 5, 17);
      final out = contributionsByMonth(
        contribs: [
          _c(999, DateTime(2024, 1, 1)), // way back
          _c(50, DateTime(2026, 5, 1)),  // in
        ],
        monthsBack: 4,
        now: now,
      );
      expect(out.fold<int>(0, (a, b) => a + b), 50);
    });
  });

  group('monthLabelsForBars', () {
    test('returns Indonesian short month names ending at now', () {
      final out = monthLabelsForBars(
        monthsBack: 4,
        now: DateTime(2026, 1, 15),
      );
      expect(out, ['Okt', 'Nov', 'Des', 'Jan']);
    });
  });
}
