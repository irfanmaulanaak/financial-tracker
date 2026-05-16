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

  test('groupByDay buckets by local day', () {
    final groups = groupByDay(sample);
    expect(groups.length, 3);
    expect(groups[DateTime(2025, 10, 5)]!.length, 2);
    expect(groups[DateTime(2025, 10, 4)]!.length, 1);
    expect(groups[DateTime(2025, 10, 3)]!.length, 1);
  });

  test('topCategories returns sorted descending', () {
    final top = topCategories(sample, limit: 2);
    expect(top.length, 2);
    expect(top[0].key, 'shopping');
    expect(top[0].value, 150000);
    expect(top[1].key, 'food');
    expect(top[1].value, 125000);
  });

  test('dailyBudget rounds monthly / cycleDays', () {
    expect(dailyBudget(monthlyBudget: 9000000, cycleDays: 30), 300000);
    expect(dailyBudget(monthlyBudget: 1000000, cycleDays: 31), 32258);
    expect(dailyBudget(monthlyBudget: 100, cycleDays: 0), 0);
  });
}
