import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/reminder_times.dart';

void main() {
  group('nextTimeOfDay', () {
    test('today when still ahead', () {
      final now = DateTime(2026, 6, 11, 8, 0);
      expect(nextTimeOfDay(now, 20, 0), DateTime(2026, 6, 11, 20, 0));
    });

    test('tomorrow when already past', () {
      final now = DateTime(2026, 6, 11, 21, 0);
      expect(nextTimeOfDay(now, 20, 0), DateTime(2026, 6, 12, 20, 0));
    });

    test('exact same minute rolls to tomorrow', () {
      final now = DateTime(2026, 6, 11, 20, 0);
      expect(nextTimeOfDay(now, 20, 0), DateTime(2026, 6, 12, 20, 0));
    });
  });

  group('nextCardDueDate', () {
    test('later this month', () {
      expect(
        nextCardDueDate(25, DateTime(2026, 6, 11)),
        DateTime(2026, 6, 25),
      );
    });

    test('due day today counts as this month', () {
      expect(
        nextCardDueDate(11, DateTime(2026, 6, 11, 15)),
        DateTime(2026, 6, 11),
      );
    });

    test('passed → next month', () {
      expect(
        nextCardDueDate(5, DateTime(2026, 6, 11)),
        DateTime(2026, 7, 5),
      );
    });

    test('clamps to short months', () {
      expect(
        nextCardDueDate(31, DateTime(2026, 2, 10)),
        DateTime(2026, 2, 28),
      );
      // Dec → Jan rollover.
      expect(
        nextCardDueDate(15, DateTime(2026, 12, 20)),
        DateTime(2027, 1, 15),
      );
    });
  });

  group('reminderMoment', () {
    test('three days before at 09:00', () {
      expect(
        reminderMoment(DateTime(2026, 6, 25), DateTime(2026, 6, 11),
            daysBefore: 3),
        DateTime(2026, 6, 22, 9),
      );
    });

    test('null when moment already passed', () {
      expect(
        reminderMoment(DateTime(2026, 6, 12), DateTime(2026, 6, 11, 10),
            daysBefore: 3),
        isNull,
      );
    });
  });
}
