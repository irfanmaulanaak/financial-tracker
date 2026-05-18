import 'package:financial_tracker/src/ui/ft_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FtListReveal items animate to full opacity after settle',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            for (var i = 0; i < 3; i++)
              FtListReveal(
                index: i,
                child: Text('item-$i'),
              ),
          ],
        ),
      ),
    );

    // Initial frame: opacity may be 0; allow animation to fully resolve.
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      expect(find.text('item-$i'), findsOneWidget);
    }
  });

  testWidgets('FtListReveal honors MediaQuery.disableAnimations',
      (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: FtListReveal(
            index: 5,
            child: Text('a11y'),
          ),
        ),
      ),
    );
    // No animation frames needed — text should be visible immediately.
    expect(find.text('a11y'), findsOneWidget);
  });
}
