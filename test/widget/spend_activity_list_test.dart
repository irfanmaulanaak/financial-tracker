import 'package:financial_tracker/src/features/expenses/expense.dart';
import 'package:financial_tracker/src/features/household/household.dart';
import 'package:financial_tracker/src/features/spend/spend_activity_list.dart';
import 'package:financial_tracker/src/features/home/widgets/recent_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Member _member(String id, String name, String color) => Member(
      userId: id,
      displayName: name,
      role: MemberRole.other,
      color: color,
      joinedAt: DateTime(2026, 1, 1),
      isCreator: id == 'a',
    );

Expense _expense(String id, int amount, String spentBy, DateTime date) =>
    Expense(
      id: id,
      amount: amount,
      categoryId: 'food',
      note: null,
      spentBy: spentBy,
      date: date,
      recurring: false,
      cardId: null,
      installmentPlanId: null,
      sourceAccountId: null,
      createdAt: date,
      createdBy: spentBy,
    );

final _household = Household(
  id: 'h1',
  name: 'Rumah',
  creatorId: 'a',
  createdAt: DateTime(2026, 1, 1),
  payday: 25,
  monthlyBudgetTotal: 0,
  memberIds: const ['a', 'b'],
  members: [
    _member('a', 'Andi', '#C4612A'),
    _member('b', 'Bima', '#3B82F6'),
  ],
  categories: const [
    Category(
        id: 'food',
        label: 'Makan',
        icon: 'restaurant',
        color: '#C4612A',
        monthlyBudget: 0),
  ],
);

/// 24 expenses: 16 by Andi, 8 by Bima, on distinct descending dates.
List<Expense> _expenses() => [
      for (var i = 0; i < 24; i++)
        _expense('e$i', 10000 + i, i < 16 ? 'a' : 'b',
            DateTime(2026, 6, 24 - i)),
    ];

Widget _harness(List<Expense> expenses) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SpendActivityList(expenses: expenses, household: _household),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID');
  });

  /// Give the test surface enough height that the pager sits on-screen and
  /// taps land on it (default 800×600 pushes it below the fold).
  void tallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('paginates 8 rows per page with prev/next', (tester) async {
    tallSurface(tester);
    await tester.pumpWidget(_harness(_expenses()));
    await tester.pumpAndSettle();

    // 24 transactions → 3 pages of 8. (Eyebrow renders uppercased.)
    expect(find.text('AKTIVITAS · 24 TRANSAKSI'), findsOneWidget);
    expect(find.text('Hal 1 dari 3'), findsOneWidget);
    expect(find.byType(ExpenseActivityRow), findsNWidgets(8));

    // Next advances through the pages.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Hal 2 dari 3'), findsOneWidget);
    expect(find.byType(ExpenseActivityRow), findsNWidgets(8));

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Hal 3 dari 3'), findsOneWidget);

    // Prev walks back.
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Hal 2 dari 3'), findsOneWidget);
  });

  testWidgets('member filter narrows the list and resets to page 1',
      (tester) async {
    tallSurface(tester);
    await tester.pumpWidget(_harness(_expenses()));
    await tester.pumpAndSettle();

    // Go to page 2 first so we can confirm the filter resets paging.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Hal 2 dari 3'), findsOneWidget);

    // Open the top-right filter and pick Bima (8 expenses → 1 page, no pager).
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Bima'));
    await tester.pumpAndSettle();

    expect(find.text('AKTIVITAS · 8 TRANSAKSI'), findsOneWidget);
    expect(find.byType(ExpenseActivityRow), findsNWidgets(8));
    expect(find.textContaining('Hal '), findsNothing);
    // Pill now reflects the selection.
    expect(find.text('Bima'), findsWidgets);
  });

  testWidgets('hides entirely when there are no expenses', (tester) async {
    await tester.pumpWidget(_harness(const []));
    await tester.pumpAndSettle();
    expect(find.byType(ExpenseActivityRow), findsNothing);
    expect(find.textContaining('Aktivitas'), findsNothing);
  });
}
