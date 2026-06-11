import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/streak.dart';

DateTime d(int day) => DateTime(2026, 6, day);

void main() {
  group('recordingStreak', () {
    test('counts consecutive days ending today', () {
      final days = {d(8), d(9), d(10)};
      expect(recordingStreak(daysWithEntries: days, today: d(10)), 3);
    });

    test('today not yet recorded → counts from yesterday (grace)', () {
      final days = {d(8), d(9)};
      expect(recordingStreak(daysWithEntries: days, today: d(10)), 2);
    });

    test('gap breaks the streak', () {
      final days = {d(6), d(7), d(9), d(10)};
      expect(recordingStreak(daysWithEntries: days, today: d(10)), 2);
    });

    test('no entries → 0', () {
      expect(
        recordingStreak(daysWithEntries: const {}, today: d(10)),
        0,
      );
    });

    test('entry two days ago only → 0 (grace is one day)', () {
      final days = {d(8)};
      expect(recordingStreak(daysWithEntries: days, today: d(10)), 0);
    });

    test('time-of-day on today is normalized', () {
      final days = {d(9), d(10)};
      expect(
        recordingStreak(
          daysWithEntries: days,
          today: DateTime(2026, 6, 10, 23, 59),
        ),
        2,
      );
    });
  });

  group('streakLabel', () {
    test('escalating supportive copy', () {
      expect(streakLabel(2), '2 hari beruntun tercatat');
      expect(streakLabel(7), contains('konsisten'));
      expect(streakLabel(30), contains('kebiasaan'));
    });
  });
}
