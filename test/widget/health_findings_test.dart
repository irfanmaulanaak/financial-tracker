import 'package:financial_tracker/src/features/expenses/expense.dart';
import 'package:financial_tracker/src/features/health/widgets/health_findings.dart';
import 'package:financial_tracker/src/features/household/household.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _categories = [
  const Category(
      id: 'food', label: 'Makan', icon: 'restaurant', color: '#C4612A', monthlyBudget: 0),
  const Category(
      id: 'fun', label: 'Hiburan', icon: 'movie', color: '#3A6075', monthlyBudget: 0),
];

Expense _expense(String cat, int amount, DateTime date) => Expense(
      id: '$cat-${date.millisecondsSinceEpoch}',
      amount: amount,
      categoryId: cat,
      note: null,
      spentBy: 'a',
      date: date,
      recurring: false,
      cardId: null,
      installmentPlanId: null,
      sourceAccountId: null,
      createdAt: date,
      createdBy: 'a',
    );

Widget _harness({required bool earlyInCycle, required List<Expense> current}) {
  return MaterialApp(
    home: Scaffold(
      body: HealthFindings(
        categories: _categories,
        current: current,
        // "fun" has history (300k) but nothing current → -100%/Rp0.
        // "food" has a real, non-zero swing (150k vs 100k avg → +50%).
        previousWindows: [
          [_expense('fun', 300000, DateTime(2026, 5, 1)), _expense('food', 100000, DateTime(2026, 5, 1))],
        ],
        earlyInCycle: earlyInCycle,
        onTap: (_) {},
      ),
    ),
  );
}

void main() {
  // Regression: early in the cycle, a category with history but nothing
  // spent yet used to show a noisy "-100%, Sekarang Rp0" row for every
  // untouched category.
  testWidgets('hides the zero-spend -100% row early in the cycle',
      (tester) async {
    await tester.pumpWidget(_harness(
      earlyInCycle: true,
      current: [_expense('food', 150000, DateTime(2026, 6, 2))],
    ));

    expect(find.textContaining('Hiburan'), findsNothing);
    expect(find.textContaining('Makan'), findsOneWidget);
  });

  testWidgets('shows the zero-spend row once past the early window',
      (tester) async {
    await tester.pumpWidget(_harness(
      earlyInCycle: false,
      current: [_expense('food', 150000, DateTime(2026, 6, 2))],
    ));

    expect(find.textContaining('Hiburan'), findsOneWidget);
    expect(find.textContaining('Sekarang Rp0'), findsOneWidget);
  });
}
