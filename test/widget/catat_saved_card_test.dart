import 'package:financial_tracker/src/core/catat_card.dart';
import 'package:financial_tracker/src/features/home/eling/catat_saved_card.dart';
import 'package:financial_tracker/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness() => const MaterialApp(
      home: Scaffold(body: SizedBox.expand()),
    );

void main() {
  testWidgets('under budget: shows the remaining amount counting down and a bar',
      (tester) async {
    await tester.pumpWidget(_harness());
    final ctx = tester.element(find.byType(Scaffold));

    CatatSavedCard.show(
      ctx,
      categoryLabel: 'Grocery',
      amountLabel: 'Rp56.300',
      amounts: const CatatCardAmounts(
          over: false, oldValue: 932006, newValue: 875706),
      budget: 2500000,
    );
    await tester.pump();

    expect(find.text('Grocery Rp56.300 tersimpan'), findsOneWidget);
    expect(find.text('Sisa Grocery'), findsOneWidget);

    // Slide-in (350ms) triggers the count via a `.then()` callback, which
    // needs one more empty pump to start ticking before advancing further.
    await tester.pump(const Duration(milliseconds: 360));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1250)); // count + hop tail

    expect(find.text('Rp876 rb'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('Pelan-pelan'), findsNothing);
  });

  testWidgets('over budget: shows the over amount in danger color, no bar',
      (tester) async {
    await tester.pumpWidget(_harness());
    final ctx = tester.element(find.byType(Scaffold));

    CatatSavedCard.show(
      ctx,
      categoryLabel: 'Belanja',
      amountLabel: 'Rp150.000',
      amounts: const CatatCardAmounts(
          over: true, oldValue: 1210605, newValue: 1360605),
      budget: 5000000,
    );
    await tester.pump();

    expect(find.text('Belanja Rp150.000 tersimpan'), findsOneWidget);
    expect(find.text('Belanja lewat'), findsOneWidget);
    expect(find.text('Pelan-pelan dulu ya.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 360));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1250));

    final numberText = tester.widget<Text>(find.text('Rp1,4 jt'));
    expect(numberText.style?.color, FtColors.danger);
  });

  testWidgets('auto-dismisses after holding for about 2 seconds',
      (tester) async {
    await tester.pumpWidget(_harness());
    final ctx = tester.element(find.byType(Scaffold));

    CatatSavedCard.show(
      ctx,
      categoryLabel: 'Grocery',
      amountLabel: 'Rp56.300',
      amounts: const CatatCardAmounts(
          over: false, oldValue: 932006, newValue: 875706),
      budget: 2500000,
    );
    await tester.pump();
    expect(find.textContaining('tersimpan'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2700));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('tersimpan'), findsNothing);
  });

  testWidgets('tapping the card dismisses it immediately', (tester) async {
    await tester.pumpWidget(_harness());
    final ctx = tester.element(find.byType(Scaffold));

    CatatSavedCard.show(
      ctx,
      categoryLabel: 'Grocery',
      amountLabel: 'Rp56.300',
      amounts: const CatatCardAmounts(
          over: false, oldValue: 932006, newValue: 875706),
      budget: 2500000,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.textContaining('tersimpan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('tersimpan'), findsNothing);
  });

  testWidgets('reduce motion shows the final numbers and holds without animating',
      (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _harness(),
    ));
    final ctx = tester.element(find.byType(Scaffold));

    CatatSavedCard.show(
      ctx,
      categoryLabel: 'Grocery',
      amountLabel: 'Rp56.300',
      amounts: const CatatCardAmounts(
          over: false, oldValue: 932006, newValue: 875706),
      budget: 2500000,
    );
    await tester.pump();

    expect(find.text('Rp876 rb'), findsOneWidget);
  });
}
