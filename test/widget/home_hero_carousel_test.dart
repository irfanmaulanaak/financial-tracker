import 'package:financial_tracker/src/core/health_score.dart';
import 'package:financial_tracker/src/core/net_worth.dart';
import 'package:financial_tracker/src/features/home/widgets/home_hero_carousel.dart';
import 'package:financial_tracker/src/ui/ft_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness() {
  final health = computeHealthScore(const HealthScoreInputs(
    spendThisCycle: 8100000,
    incomeThisCycle: 14500000,
    monthlyBudget: 12000000,
    savingsBalance: 27000000,
    cardDebt: 5700000,
    avgMonthlySpend: 7600000,
    investmentCount: 3,
  ));
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: HomeHeroCarousel(
          nw: const NetWorth(
            cash: 10000000,
            savings: 20000000,
            investments: 5000000,
            debt: 2000000,
          ),
          trend: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
          cycleNet: 1000000,
          spend: 8100000,
          gajiIncome: 14500000,
          cards: const [],
          health: health,
        ),
      ),
    ),
  );
}

void main() {
  // Regression: sparkline used to collapse to ~0 width when its parent
  // column didn't impose one, rendering 14 points as a 2px stub.
  testWidgets('hero sparkline gets a real width', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump(const Duration(milliseconds: 700));
    final size = tester.getSize(find.byType(FtSparkline));
    expect(size.width, greaterThan(100));
  });

  // Regression: dots were purely decorative, leaving slides 2-4 unreachable
  // with a mouse (PageView ignores mouse drags on web by default).
  testWidgets('tapping a dot navigates to that slide', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump(const Duration(milliseconds: 700));

    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller;
    expect(controller?.page, 0);

    await tester.tap(find.bySemanticsLabel('Slide 4 dari 4'));
    await tester.pumpAndSettle();
    expect(controller?.page, 3);
  });
}
