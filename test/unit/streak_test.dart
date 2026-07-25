import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/streak.dart';

DateTime d(int day) => DateTime(2026, 6, day);

void main() {
  group('recordingStreak', () {
    test('counts consecutive days ending today', () {
      final days = {d(8), d(9), d(10)};
      expect(recordingStreak(daysWithEntries: days, today: d(10)), 3);
    });

    test('today not yet recorded → counts from yesterday', () {
      final days = {d(8), d(9)};
      expect(recordingStreak(daysWithEntries: days, today: d(10)), 2);
    });

    test('satu hari bolong dimaafkan (grace), tidak ikut dihitung', () {
      final days = {d(6), d(7), d(9), d(10)};
      expect(recordingStreak(daysWithEntries: days, today: d(10)), 4);
    });

    test('dua hari bolong terpisah → putus di bolong kedua', () {
      final days = {d(5), d(6), d(8), d(10)};
      // 10✓ 9bolong(grace) 8✓ 7bolong → stop.
      expect(recordingStreak(daysWithEntries: days, today: d(10)), 2);
    });

    test('dua hari bolong berurutan → putus', () {
      final days = {d(7), d(10)};
      expect(recordingStreak(daysWithEntries: days, today: d(10)), 1);
    });

    test('no entries → 0', () {
      expect(
        recordingStreak(daysWithEntries: const {}, today: d(10)),
        0,
      );
    });

    test('entry dua hari lalu saja → 1 (kemarin kena grace)', () {
      final days = {d(8)};
      expect(recordingStreak(daysWithEntries: days, today: d(10)), 1);
    });

    test('grace 0 → perilaku ketat lama', () {
      final days = {d(6), d(7), d(9), d(10)};
      expect(
        recordingStreak(daysWithEntries: days, today: d(10), grace: 0),
        2,
      );
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
    test('plain factual copy', () {
      expect(streakLabel(2), '2 hari beruntun tercatat');
      expect(streakLabel(7), '7 hari beruntun tercatat');
      expect(streakLabel(30), '30 hari beruntun tercatat');
    });
  });
}
