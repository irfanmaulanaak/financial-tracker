import 'package:financial_tracker/src/core/formatters.dart';
import 'package:financial_tracker/src/features/categories/widgets/category_detail_header_card.dart';
import 'package:financial_tracker/src/features/expenses/expense.dart';
import 'package:financial_tracker/src/features/household/household.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _category = Category(
  id: 'food',
  label: 'Makan',
  icon: 'restaurant',
  color: '#C4612A',
  monthlyBudget: 5000000,
);

Expense _expense(int amount, DateTime date) => Expense(
      id: 'e$amount',
      amount: amount,
      categoryId: 'food',
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

// 30 Sep to 29 Okt 2026, which is 30 days.
final _pastCycle = (
  start: DateTime(2026, 9, 30),
  endExclusive: DateTime(2026, 10, 30),
);

const _noBudget = Category(
  id: 'food',
  label: 'Surabaya',
  icon: 'restaurant',
  color: '#C4612A',
  monthlyBudget: 0,
);

Widget _harness(
  AsyncValue<List<Expense>> expenses, {
  int cyclesBack = 1,
  Category category = _category,
}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CategoryDetailHeaderCard(
            category: category,
            expensesAsync: expenses,
            prevAsync: const AsyncData(<List<Expense>>[]),
            cycle: _pastCycle,
            cyclesBack: cyclesBack,
            color: Colors.orange,
            canMoveBudget: false,
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('past cycle shows its range, spent, and daily average over the '
      'full cycle length', (tester) async {
    final expenses = [
      _expense(2000000, DateTime(2026, 10, 1)),
      _expense(1000000, DateTime(2026, 10, 20)),
    ];
    await tester.pumpWidget(_harness(AsyncData(expenses)));

    expect(find.text('Siklus 30 Sep sampai 29 Okt'), findsOneWidget);
    expect(find.text('Pengeluaran siklus ini'), findsNothing);
    expect(find.text(Money.format(3000000)), findsOneWidget);
    // 3.000.000 / 30 days, not divided by days since the cycle started.
    expect(find.text(Money.format(100000)), findsOneWidget);
    expect(find.text('hari ini'), findsNothing);
  });

  void expectNoBudgetCard(WidgetTester tester) {
    expect(find.text(Money.format(3000000)), findsWidgets);
    expect(find.text('Belum ada anggaran untuk kategori ini.'), findsOneWidget);
    expect(find.textContaining('Over'), findsNothing);
    expect(find.textContaining('Aman'), findsNothing);
    expect(find.textContaining('Melebihi anggaran'), findsNothing);
    expect(find.textContaining('terpakai'), findsNothing);
    expect(find.text('Geser anggaran'), findsNothing);
  }

  testWidgets('no budget, past cycle: no Over, no warning, still shows spent',
      (tester) async {
    await tester.pumpWidget(_harness(
      AsyncData([_expense(3000000, DateTime(2026, 10, 1))]),
      category: _noBudget,
    ));
    expectNoBudgetCard(tester);
  });

  testWidgets('no budget, current cycle: no chip, no warning', (tester) async {
    await tester.pumpWidget(_harness(
      AsyncData([_expense(3000000, DateTime.now())]),
      cyclesBack: 0,
      category: _noBudget,
    ));
    expect(find.text('Pengeluaran siklus ini'), findsOneWidget);
    expectNoBudgetCard(tester);
  });

  testWidgets('with a budget and spent above it, still shows Over and warning',
      (tester) async {
    await tester.pumpWidget(_harness(
      AsyncData([_expense(6000000, DateTime(2026, 10, 1))]),
    ));
    expect(find.textContaining('Over'), findsOneWidget);
    expect(find.textContaining('Melebihi anggaran 20%'), findsOneWidget);
    expect(find.textContaining('terpakai'), findsOneWidget);
    expect(find.text('Belum ada anggaran untuk kategori ini.'), findsNothing);
  });

  testWidgets('cyclesBack 0 keeps the current-cycle eyebrow', (tester) async {
    await tester.pumpWidget(
      _harness(const AsyncData(<Expense>[]), cyclesBack: 0),
    );
    expect(find.text('Pengeluaran siklus ini'), findsOneWidget);
    expect(find.text('hari ini'), findsOneWidget);
  });
}
