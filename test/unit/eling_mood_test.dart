import 'package:financial_tracker/src/features/home/eling/eling_mood.dart';
import 'package:flutter_test/flutter_test.dart';

// A plain daytime moment so time-of-day never trips the Bobo rule by accident.
DateTime _day() => DateTime(2026, 10, 16, 10);

// Baseline is comfortably Senang: perDay*cycleLength (6jt) >= 0.5*budget (3jt)
// and remaining > 0, so individual tests flip exactly one input.
ElingMood _mood({
  DateTime? now,
  bool hasBudget = true,
  int remaining = 500000,
  int perDay = 200000,
  int cycleLength = 30,
  int monthlyBudget = 6000000,
  bool noSpendYesterday = false,
}) =>
    elingMood(
      now: now ?? _day(),
      hasBudget: hasBudget,
      remaining: remaining,
      perDay: perDay,
      cycleLength: cycleLength,
      monthlyBudget: monthlyBudget,
      noSpendYesterday: noSpendYesterday,
    );

void main() {
  group('rule 1 — Bobo (21:00–04:59)', () {
    test('at 21:00 and 04:59', () {
      expect(_mood(now: DateTime(2026, 10, 16, 21)), ElingMood.bobo);
      expect(_mood(now: DateTime(2026, 10, 16, 4, 59)), ElingMood.bobo);
      expect(_mood(now: DateTime(2026, 10, 16, 23, 30)), ElingMood.bobo);
    });

    test('not Bobo at 05:00 or 20:59', () {
      expect(_mood(now: DateTime(2026, 10, 16, 5)), isNot(ElingMood.bobo));
      expect(_mood(now: DateTime(2026, 10, 16, 20, 59)), isNot(ElingMood.bobo));
    });

    test('wins over every later rule', () {
      // Ngirit + Hore conditions both hold, but it's night → Bobo.
      expect(
        _mood(
          now: DateTime(2026, 10, 16, 22),
          remaining: -1,
          noSpendYesterday: true,
        ),
        ElingMood.bobo,
      );
    });
  });

  group('rule 2 — Ngirit', () {
    test('when remaining <= 0 and there is a budget', () {
      expect(_mood(remaining: 0), ElingMood.ngirit);
      expect(_mood(remaining: -5000), ElingMood.ngirit);
    });

    test('when perDay * cycleLength < 0.5 * monthlyBudget', () {
      // 20000 * 30 = 600k < 0.5 * 6jt = 3jt.
      expect(
        _mood(remaining: 900000, perDay: 20000, cycleLength: 30, monthlyBudget: 6000000),
        ElingMood.ngirit,
      );
    });

    test('needs a budget — skipped when hasBudget is false', () {
      expect(_mood(hasBudget: false, remaining: -1), isNot(ElingMood.ngirit));
    });

    test('wins over Hore', () {
      expect(
        _mood(remaining: -1, noSpendYesterday: true),
        ElingMood.ngirit,
      );
    });
  });

  group('rule 3 — Hore', () {
    test('when nothing was spent yesterday', () {
      expect(_mood(noSpendYesterday: true), ElingMood.hore);
    });

    test('also when there is no budget (Ngirit cannot apply)', () {
      expect(
        _mood(hasBudget: false, remaining: -1, noSpendYesterday: true),
        ElingMood.hore,
      );
    });
  });

  group('rule 4 — Senang (default)', () {
    test('everything else', () {
      expect(_mood(), ElingMood.senang);
    });
  });

  test('elingLine gives each mood its default line', () {
    expect(elingLine(ElingMood.senang), 'Hari ini masih aman.');
    expect(elingLine(ElingMood.ngirit),
        'Pelan-pelan dulu ya, sisa anggaran tinggal sedikit.');
    expect(elingLine(ElingMood.bobo), 'Selamat istirahat. Besok kita cek lagi.');
    expect(elingLine(ElingMood.hore), 'Kemarin nggak ada jajan. Mantap!');
  });
}
