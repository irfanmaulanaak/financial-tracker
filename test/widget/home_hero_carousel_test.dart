import 'package:financial_tracker/src/core/health_score.dart';
import 'package:financial_tracker/src/core/hide_assets_provider.dart';
import 'package:financial_tracker/src/core/net_worth.dart';
import 'package:financial_tracker/src/features/home/widgets/home_hero_carousel.dart';
import 'package:financial_tracker/src/ui/ft_sparkline.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _AssetsShown extends HideAssetsNotifier {
  @override
  bool build() => false;
}

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
    // Assets start hidden (privacy default), which also disables sparkline
    // scrubbing — reveal them so the hover readout is testable.
    overrides: [hideAssetsProvider.overrideWith(_AssetsShown.new)],
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
          trendDates: [
            for (var d = 0; d < 14; d++) DateTime(2026, 5, 29 + d),
          ],
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
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID');
  });

  // Regression: sparkline used to collapse to ~0 width when its parent
  // column didn't impose one, rendering 14 points as a 2px stub.
  testWidgets('hero sparkline gets a real width', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump(const Duration(milliseconds: 700));
    final size = tester.getSize(find.byType(FtSparkline));
    expect(size.width, greaterThan(100));
  });

  // Scrub: hovering the sparkline shows the per-day readout (date · value)
  // and leaving hides it again.
  testWidgets('hovering the sparkline shows the daily value', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.textContaining('· Rp'), findsNothing);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(find.byType(FtSparkline)));
    await tester.pump();

    // Center of 14 points (29 Mei .. 11 Jun) ≈ index 6/7 → a real date+value.
    expect(find.textContaining('· Rp'), findsOneWidget);

    await gesture.moveTo(Offset.zero);
    await tester.pump();
    expect(find.textContaining('· Rp'), findsNothing);
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
