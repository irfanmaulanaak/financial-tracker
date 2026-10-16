import 'package:financial_tracker/src/features/household/household.dart';
import 'package:financial_tracker/src/features/record_common/category_chip_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Category _cat(String id, String label, String icon) => Category(
      id: id,
      label: label,
      icon: icon,
      color: '#C4612A',
      monthlyBudget: 0,
    );

void main() {
  // Regression: a custom category that never had an icon picked (icon
  // 'category', same as the seeded "Lainnya" default) used to render the
  // same generic icon as every other un-set category — now a neutral dot.
  testWidgets('custom category with no icon chosen shows a neutral dot',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CategoryChipRow(
          categories: [_cat('mama', 'Mama', 'category')],
          selected: null,
          onSelect: (_) {},
        ),
      ),
    ));

    expect(find.byIcon(Icons.category), findsNothing);
  });

  testWidgets('the seeded Lainnya category keeps its generic icon',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CategoryChipRow(
          categories: [_cat('other', 'Lainnya', 'category')],
          selected: null,
          onSelect: (_) {},
        ),
      ),
    ));

    expect(find.byIcon(Icons.category), findsOneWidget);
  });

  testWidgets('a category with a real icon shows it, not a dot',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CategoryChipRow(
          categories: [_cat('food', 'Makan', 'restaurant')],
          selected: null,
          onSelect: (_) {},
        ),
      ),
    ));

    expect(find.byIcon(Icons.restaurant), findsOneWidget);
  });
}
