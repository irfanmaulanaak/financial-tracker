import 'package:financial_tracker/src/features/record_common/money_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression: the "0" placeholder used to render under the blinking
  // cursor the moment the field was focused (both sit at offset 0 on an
  // empty, left-aligned field). Now the hint hides while focused.
  testWidgets('the "0" hint disappears once the field is focused',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MoneyField(amount: 0, onChanged: (_) {}, autofocus: false),
      ),
    ));

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(find.text('0'), findsNothing);
  });

  testWidgets('+/- chips carry an accessible label explaining what they do',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MoneyField(
          amount: 0,
          onChanged: (_) {},
          autofocus: true,
          calculator: true,
        ),
      ),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('Tambah item lagi'), findsOneWidget);
    expect(find.bySemanticsLabel('Kurangi dari total'), findsOneWidget);
  });
}
