import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/stable_income.dart';

void main() {
  group('stableSalary', () {
    // Payday 30, weekend rollback ada di payday.dart (sudah diuji terpisah).
    final now = DateTime(2026, 8, 1);

    test('rata-rata siklus lengkap; siklus berjalan tidak ikut', () {
      final r = stableSalary(
        salaryIncomes: [
          // Siklus berjalan (mulai 30 Jul) — harus diabaikan.
          (date: DateTime(2026, 7, 30), amount: 15_000_000),
          // Siklus 30 Jun–30 Jul.
          (date: DateTime(2026, 6, 30), amount: 15_700_000),
          (date: DateTime(2026, 7, 11), amount: 26_900_000),
          // Siklus 29 Mei–30 Jun (29 Mei = Jumat, payday 30 Mei = Sabtu mundur).
          (date: DateTime(2026, 6, 14), amount: 26_400_000),
          (date: DateTime(2026, 5, 29), amount: 15_000_000),
        ],
        now: now,
        payday: 30,
      );
      // (42.6jt + 41.4jt) / 2
      expect(r, (42_600_000 + 41_400_000) ~/ 2);
    });

    test('siklus tanpa gaji dilewati, bukan dihitung nol', () {
      final r = stableSalary(
        salaryIncomes: [
          (date: DateTime(2026, 7, 1), amount: 40_000_000),
          // Siklus Mei & Juni kosong.
        ],
        now: now,
        payday: 30,
      );
      expect(r, 40_000_000);
    });

    test('tanpa riwayat sama sekali: 0', () {
      final r = stableSalary(salaryIncomes: [], now: now, payday: 30);
      expect(r, 0);
    });

    test('gaji di siklus berjalan saja: 0 (belum ada siklus lengkap)', () {
      final r = stableSalary(
        salaryIncomes: [(date: DateTime(2026, 7, 30), amount: 15_000_000)],
        now: now,
        payday: 30,
      );
      expect(r, 0);
    });
  });
}
