import 'package:financial_tracker/src/features/expenses/expense.dart';
import 'package:financial_tracker/src/features/home/widgets/recent_list.dart';
import 'package:financial_tracker/src/features/household/household.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final _category = const Category(
  id: 'food',
  label: 'Makan',
  icon: 'restaurant',
  color: '#C4612A',
  monthlyBudget: 0,
);

final _member = Member(
  userId: 'a',
  displayName: 'Andi',
  role: MemberRole.other,
  color: '#3B82F6',
  joinedAt: DateTime(2026, 1, 1),
  isCreator: true,
);

Expense _expense({String? note}) => Expense(
      id: 'e1',
      amount: 45000,
      categoryId: 'food',
      note: note,
      spentBy: 'a',
      date: DateTime(2026, 6, 10),
      recurring: false,
      cardId: null,
      installmentPlanId: null,
      sourceAccountId: null,
      createdAt: DateTime(2026, 6, 10),
      createdBy: 'a',
    );

Widget _harness(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID');
  });

  // Regression: title used to always be the category, with the note as a
  // small cut-off subtitle. Now the note is the title.
  testWidgets('title is the note; subtitle is category · date',
      (tester) async {
    await tester.pumpWidget(_harness(ExpenseActivityRow(
      expense: _expense(note: 'rumah susu sudiro batu'),
      category: _category,
      spender: null,
    )));

    expect(find.text('rumah susu sudiro batu'), findsOneWidget);
    expect(find.textContaining('Makan ·'), findsOneWidget);
  });

  testWidgets('falls back to the category name when the note is empty',
      (tester) async {
    await tester.pumpWidget(_harness(ExpenseActivityRow(
      expense: _expense(note: null),
      category: _category,
      spender: null,
    )));

    expect(find.text('Makan'), findsOneWidget);
  });

  // Regression: spender used to always render as a long name chip; now it's
  // a small initial avatar, and only shown when the caller passes one in
  // (i.e. "Semua Anggota" is selected upstream).
  testWidgets('spender renders as a small initial, not a name chip',
      (tester) async {
    await tester.pumpWidget(_harness(ExpenseActivityRow(
      expense: _expense(),
      category: _category,
      spender: _member,
    )));

    expect(find.text('Andi'), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('no spender avatar when none is passed', (tester) async {
    await tester.pumpWidget(_harness(ExpenseActivityRow(
      expense: _expense(),
      category: _category,
      spender: null,
    )));

    expect(find.text('A'), findsNothing);
  });
}
