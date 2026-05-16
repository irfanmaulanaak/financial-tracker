import 'package:financial_tracker/src/core/category_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('analyseCategory', () {
    test('empty history → not enough data', () {
      final r = analyseCategory(
        categoryId: 'food',
        currentSpend: 500000,
        previousSpends: const [],
      );
      expect(r.verdict, 'Belum cukup data');
      expect(r.historicalAverage, 0);
    });

    test('zero current + zero history → no expenses', () {
      final r = analyseCategory(
        categoryId: 'food',
        currentSpend: 0,
        previousSpends: const [0, 0, 0],
      );
      expect(r.verdict, 'Tidak ada pengeluaran');
    });

    test('current within ±10% of avg → stable', () {
      final r = analyseCategory(
        categoryId: 'food',
        currentSpend: 1050000,
        previousSpends: const [1000000, 1000000, 1000000],
      );
      expect(r.verdict, 'Stabil');
      expect(r.deltaPct, closeTo(0.05, 0.001));
    });

    test('current > 50% above avg → sangat boros', () {
      final r = analyseCategory(
        categoryId: 'food',
        currentSpend: 1600000,
        previousSpends: const [1000000, 1000000, 1000000],
      );
      expect(r.verdict, 'Sangat boros');
    });

    test('current 11-49% above avg → boros', () {
      final r = analyseCategory(
        categoryId: 'food',
        currentSpend: 1300000,
        previousSpends: const [1000000, 1000000],
      );
      expect(r.verdict, 'Boros');
    });

    test('current more than 10% below avg → lebih hemat', () {
      final r = analyseCategory(
        categoryId: 'food',
        currentSpend: 700000,
        previousSpends: const [1000000, 1000000],
      );
      expect(r.verdict, 'Lebih hemat');
    });

    test('avg is 0 but current > 0 → new this cycle', () {
      final r = analyseCategory(
        categoryId: 'health',
        currentSpend: 200000,
        previousSpends: const [0, 0, 0],
      );
      expect(r.verdict, 'Baru muncul siklus ini');
    });
  });

  group('dailyPattern', () {
    test('empty input → all zero', () {
      expect(dailyPattern([]), List.filled(7, 0.0));
    });

    test('single day → 100% in that bucket', () {
      // 2025-09-30 is Tue (weekday 2 → index 1).
      final r = dailyPattern([
        (date: DateTime(2025, 9, 30), amount: 50000),
      ]);
      expect(r[1], 1.0);
      for (var i = 0; i < 7; i++) {
        if (i != 1) expect(r[i], 0.0);
      }
    });

    test('shares sum to 1.0', () {
      final r = dailyPattern([
        (date: DateTime(2025, 9, 29), amount: 30000), // Mon
        (date: DateTime(2025, 9, 30), amount: 70000), // Tue
      ]);
      expect(r[0], closeTo(0.3, 0.001));
      expect(r[1], closeTo(0.7, 0.001));
      expect(r.fold<double>(0, (a, b) => a + b), closeTo(1.0, 0.001));
    });
  });
}
