import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/budget_move.dart';
import 'package:financial_tracker/src/features/household/household.dart';

Category cat(String id, int budget, {bool archived = false}) => Category(
      id: id,
      label: id,
      icon: 'category',
      color: '#000000',
      monthlyBudget: budget,
      archived: archived,
    );

void main() {
  final cats = [cat('makan', 1000000), cat('transport', 500000)];

  group('applyBudgetMove', () {
    test('memindahkan jumlah dari → ke', () {
      final r = applyBudgetMove(
        categories: cats,
        fromId: 'transport',
        toId: 'makan',
        amount: 200000,
      );
      expect(r.error, isNull);
      final by = {for (final c in r.categories!) c.id: c.monthlyBudget};
      expect(by['transport'], 300000);
      expect(by['makan'], 1200000);
    });

    test('total anggaran tidak berubah', () {
      final r = applyBudgetMove(
        categories: cats,
        fromId: 'makan',
        toId: 'transport',
        amount: 999999,
      );
      final total = r.categories!
          .fold<int>(0, (a, c) => a + c.monthlyBudget);
      expect(total, 1500000);
    });

    test('melebihi anggaran sumber → insufficient_budget', () {
      final r = applyBudgetMove(
        categories: cats,
        fromId: 'transport',
        toId: 'makan',
        amount: 500001,
      );
      expect(r.error, 'insufficient_budget');
      expect(r.categories, isNull);
    });

    test('kategori sama → same_category', () {
      final r = applyBudgetMove(
        categories: cats,
        fromId: 'makan',
        toId: 'makan',
        amount: 1,
      );
      expect(r.error, 'same_category');
    });

    test('jumlah nol/negatif → invalid_amount', () {
      expect(
        applyBudgetMove(
                categories: cats,
                fromId: 'transport',
                toId: 'makan',
                amount: 0)
            .error,
        'invalid_amount',
      );
    });

    test('kategori hilang/arsip → category_missing', () {
      expect(
        applyBudgetMove(
                categories: cats, fromId: 'x', toId: 'makan', amount: 1)
            .error,
        'category_missing',
      );
      final withArchived = [...cats, cat('lama', 100, archived: true)];
      expect(
        applyBudgetMove(
                categories: withArchived,
                fromId: 'lama',
                toId: 'makan',
                amount: 1)
            .error,
        'category_missing',
      );
    });
  });

  group('appendBudgetMove', () {
    BudgetMove mv(int minute) => BudgetMove(
          fromId: 'a',
          toId: 'b',
          amount: 1,
          by: 'u',
          at: DateTime(2026, 6, 1, 0, minute),
        );

    test('terbaru di depan, dibatasi cap', () {
      var list = <BudgetMove>[];
      for (var m = 1; m <= 35; m++) {
        list = appendBudgetMove(list, mv(m), cap: 30);
      }
      expect(list.length, 30);
      expect(list.first.at.minute, 35);
      expect(list.last.at.minute, 6);
    });
  });

  group('movesInCycle', () {
    test('filter berdasarkan rentang siklus', () {
      final moves = [
        BudgetMove(
            fromId: 'a',
            toId: 'b',
            amount: 1,
            by: 'u',
            at: DateTime(2026, 5, 30)),
        BudgetMove(
            fromId: 'a',
            toId: 'b',
            amount: 2,
            by: 'u',
            at: DateTime(2026, 6, 5)),
      ];
      final inCycle = movesInCycle(
        moves,
        start: DateTime(2026, 6, 1),
        endExclusive: DateTime(2026, 7, 1),
      );
      expect(inCycle.length, 1);
      expect(inCycle.single.amount, 2);
    });
  });
}
