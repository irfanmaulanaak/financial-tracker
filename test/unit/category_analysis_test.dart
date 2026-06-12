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
}
