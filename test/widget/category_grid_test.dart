import 'package:financial_tracker/src/features/home/widgets/category_grid.dart';
import 'package:financial_tracker/src/features/household/household.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(String id, {int budget = 0}) => Category(
      id: id,
      label: id,
      icon: 'restaurant',
      color: '#C4612A',
      monthlyBudget: budget,
      sortOrder: 0,
    );

Widget _harness(List<Category> categories, Map<String, int> totals) {
  return MaterialApp(
    home: Scaffold(
      body: CategoryGrid(categories: categories, totals: totals, onTap: () {}),
    ),
  );
}

void main() {
  // Regression: a category with no budget used to still render an (empty)
  // progress bar, so the bar said nothing. Now there's no bar at all.
  testWidgets('a category with no budget shows no progress bar',
      (tester) async {
    await tester.pumpWidget(_harness([_cat('food')], {'food': 50000}));

    expect(find.text('tanpa budget'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('a category with a budget shows a progress bar and percent',
      (tester) async {
    await tester.pumpWidget(
      _harness([_cat('food', budget: 100000)], {'food': 50000}),
    );

    expect(find.text('50% terpakai'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
