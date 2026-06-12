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

  group('nextWeekdayTime', () {
    test('minggu yang sama bila masih di depan', () {
      // 11 Jun 2026 = Kamis. Minggu berikutnya = 14 Jun.
      expect(
        nextWeekdayTime(DateTime(2026, 6, 11), DateTime.sunday, 18, 0),
        DateTime(2026, 6, 14, 18, 0),
      );
    });

    test('hari sama tapi jam lewat → minggu depan', () {
      // 14 Jun 2026 = Minggu, 19:00 sudah lewat 18:00.
      expect(
        nextWeekdayTime(DateTime(2026, 6, 14, 19), DateTime.sunday, 18, 0),
        DateTime(2026, 6, 21, 18, 0),
      );
    });
  });

  group('nextMoneyDateMoment', () {
    test('2 hari sebelum gajian berikutnya jam 19.30', () {
      // Payday 25. Now 11 Jun → next payday 25 Jun (Kamis, bukan weekend).
      expect(
        nextMoneyDateMoment(DateTime(2026, 6, 11), 25),
        DateTime(2026, 6, 23, 19, 30),
      );
    });

    test('momen siklus ini lewat → siklus berikutnya', () {
      // Now 24 Jun (sudah lewat 23 Jun 19.30) → payday berikutnya 24 Jul
      // (24 Jul 2026 = Jumat) → momen 22 Jul 19.30.
      final m = nextMoneyDateMoment(DateTime(2026, 6, 24), 25);
      expect(m.isAfter(DateTime(2026, 6, 24)), isTrue);
      expect(m.month, 7);
      expect(m.hour, 19);
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
