import 'package:financial_tracker/src/core/seeded_data.dart';
import 'package:financial_tracker/src/features/household/household.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(String id, {bool isInvestment = false}) => Category(
      id: id,
      label: id,
      icon: 'category',
      color: '#A89880',
      monthlyBudget: 0,
      isInvestment: isInvestment,
    );

void main() {
  group('Category.isInvestment', () {
    test('round-trips through toMap/fromMap', () {
      final c = _cat('investment', isInvestment: true);
      final back = Category.fromMap(c.toMap());
      expect(back.isInvestment, isTrue);
    });

    test('defaults to false for legacy maps without the field', () {
      final back = Category.fromMap({'id': 'food', 'label': 'Makanan'});
      expect(back.isInvestment, isFalse);
    });

    test('copyWith can flip the flag', () {
      final c = _cat('emas');
      expect(c.copyWith(isInvestment: true).isInvestment, isTrue);
      expect(c.copyWith(label: 'Emas').isInvestment, isFalse);
    });
  });

  test('Household.investmentCategoryIds collects flagged categories only', () {
    final h = Household(
      id: 'h1',
      name: 'Rumah',
      creatorId: 'u1',
      createdAt: DateTime(2026, 1, 1),
      payday: 25,
      monthlyBudgetTotal: 0,
      memberIds: const ['u1'],
      members: const [],
      categories: [
        _cat('food'),
        _cat('investment', isInvestment: true),
        _cat('emas', isInvestment: true),
      ],
    );
    expect(h.investmentCategoryIds, {'investment', 'emas'});
  });

  test('seeded Investasi category carries the investment flag', () {
    final inv = seededCategories.firstWhere((c) => c.id == 'investment');
    expect(inv.isInvestment, isTrue);
    expect(inv.label, 'Investasi');
    // No other seeded category is flagged.
    expect(
      seededCategories.where((c) => c.isInvestment).length,
      1,
    );
  });
}
