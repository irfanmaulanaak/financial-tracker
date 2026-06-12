import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/daily_insight.dart';

void main() {
  const cat = (id: 'a', label: 'Makan', budget: 1000000, spent: 0);

  group('dailyInsight', () {
    test('prioritas 1: kategori hampir limit (85-99%)', () {
      final s = dailyInsight(
        categories: [
          (id: 'a', label: 'Makan', budget: 1000000, spent: 900000),
        ],
        prevSpentById: const {},
        totalSpent: 900000,
        totalBudget: 5000000,
        daysElapsed: 10,
        cycleLength: 30,
        noSpendYesterday: false,
      );
      expect(s, contains('Makan'));
      expect(s, contains('90%'));
    });

    test('kategori sudah lewat 100% tidak memicu aturan hampir-limit', () {
      final s = dailyInsight(
        categories: [
          (id: 'a', label: 'Makan', budget: 1000000, spent: 1200000),
        ],
        prevSpentById: const {},
        totalSpent: 1200000,
        totalBudget: 5000000,
        daysElapsed: 15,
        cycleLength: 30,
        noSpendYesterday: false,
      );
      expect(s, isNot(contains('hampir')));
    });

    test('prioritas 2: laju cepat (spent% - elapsed% >= 15)', () {
      final s = dailyInsight(
        categories: [cat],
        prevSpentById: const {},
        totalSpent: 2500000, // 50%
        totalBudget: 5000000,
        daysElapsed: 9, // 30%
        cycleLength: 30,
        noSpendYesterday: false,
      );
      expect(s, contains('50% anggaran'));
    });

    test('prioritas 3: hemat vs siklus lalu (prorata)', () {
      final s = dailyInsight(
        categories: [
          (id: 'a', label: 'Jajan', budget: 0, spent: 100000),
        ],
        // Prev 600rb; di hari 15/30 prorata = 300rb → hemat 200rb (≥20%).
        prevSpentById: const {'a': 600000},
        totalSpent: 100000,
        totalBudget: 5000000,
        daysElapsed: 15,
        cycleLength: 30,
        noSpendYesterday: false,
      );
      expect(s, contains('Hemat'));
      expect(s, contains('Jajan'));
    });

    test('prioritas 4: kemarin nol belanja', () {
      final s = dailyInsight(
        categories: [cat],
        prevSpentById: const {},
        totalSpent: 100000,
        totalBudget: 0,
        daysElapsed: 5,
        cycleLength: 30,
        noSpendYesterday: true,
      );
      expect(s, contains('Kemarin nol pengeluaran'));
    });

    test('prioritas 5: laju terkendali', () {
      final s = dailyInsight(
        categories: [cat],
        prevSpentById: const {},
        totalSpent: 500000, // 10%
        totalBudget: 5000000,
        daysElapsed: 15, // 50%
        cycleLength: 30,
        noSpendYesterday: false,
      );
      expect(s, contains('terkendali'));
    });

    test('tanpa data berarti: null', () {
      final s = dailyInsight(
        categories: [cat],
        prevSpentById: const {},
        totalSpent: 0,
        totalBudget: 5000000,
        daysElapsed: 1,
        cycleLength: 30,
        noSpendYesterday: true, // diabaikan karena belum ada spend
      );
      expect(s, isNull);
    });
  });
}
