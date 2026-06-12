import 'package:financial_tracker/src/core/expense_aggregations.dart';
import 'package:flutter_test/flutter_test.dart';

ExpenseRecord _e(num amount, String cat, String uid, DateTime d) =>
    ExpenseRecord(amount: amount, categoryId: cat, spentBy: uid, date: d);

void main() {
  final sample = <ExpenseRecord>[
    _e(50000, 'food', 'u1', DateTime(2025, 10, 5, 12)),
    _e(20000, 'transport', 'u2', DateTime(2025, 10, 5, 18)),
    _e(75000, 'food', 'u2', DateTime(2025, 10, 4, 19)),
    _e(150000, 'shopping', 'u1', DateTime(2025, 10, 3, 11)),
  ];

  test('totalSpent sums all amounts', () {
    expect(totalSpent(sample), 295000);
    expect(totalSpent(const <ExpenseRecord>[]), 0);
  });

  group('consumptionOnly', () {
    final withInvestment = [
      ...sample,
      _e(500000, 'investment', 'u1', DateTime(2025, 10, 6, 9)),
    ];

    test('drops investment-category expenses from totals', () {
      final spend = consumptionOnly(withInvestment, {'investment'});
      expect(totalSpent(spend), 295000); // 795000 minus the investment
      expect(spend.length, sample.length);
      expect(
        spentByCategory(spend).containsKey('investment'),
        isFalse,
      );
    });

    test('original list keeps the investment expense (stays in lists)', () {
      expect(totalSpent(withInvestment), 795000);
      expect(withInvestment.any((e) => e.categoryId == 'investment'), isTrue);
    });

    test('no investment categories → unchanged', () {
      expect(totalSpent(consumptionOnly(sample, const {})), 295000);
    });
  });

  test('spentByCategory aggregates per category', () {
    final m = spentByCategory(sample);
    expect(m['food'], 125000);
    expect(m['transport'], 20000);
    expect(m['shopping'], 150000);
    expect(m.containsKey('bills'), isFalse);
  });

  test('spentByMember aggregates per uid', () {
    final m = spentByMember(sample);
    expect(m['u1'], 200000);
    expect(m['u2'], 95000);
  });
}
