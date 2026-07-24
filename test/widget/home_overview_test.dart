import 'package:financial_tracker/src/core/health_score.dart';
import 'package:financial_tracker/src/core/hide_assets_provider.dart';
import 'package:financial_tracker/src/core/net_worth.dart';
import 'package:financial_tracker/src/features/home/widgets/home_overview.dart';
import 'package:financial_tracker/src/ui/ft_sparkline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _AssetsShown extends HideAssetsNotifier {
  @override
  bool build() => false;
}

Widget _harness() {
  return ProviderScope(
    overrides: [hideAssetsProvider.overrideWith(_AssetsShown.new)],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeOverview(
            nw: const NetWorth(
              cash: 10000000,
              savings: 20000000,
              investments: 5000000,
              debt: 2000000,
            ),
            trend: const [1, 2, 3, 4, 5, 6, 7],
            trendDates: [
              for (var day = 1; day <= 7; day++) DateTime(2026, 7, day),
            ],
            cycleNet: 1000000,
            spend: 8100000,
            gajiIncome: 14500000,
            cards: const [],
            health: computeHealthScore(
              const HealthScoreInputs(
                spendThisCycle: 8100000,
                incomeThisCycle: 14500000,
                monthlyBudget: 12000000,
                savingsBalance: 27000000,
                cardDebt: 5700000,
                avgMonthlySpend: 7600000,
                investmentCount: 3,
              ),
            ),
            safe: (
              perDay: 150000,
              remaining: 3000000,
              daysLeft: 20,
              nextPayday: DateTime(2026, 8, 1),
              hasBudget: true,
            ),
          ),
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

  testWidgets('shows all core financial summaries without a carousel', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_harness());

    expect(find.text('Rp150.000/hari'), findsOneWidget);
    final heroValue = tester.widget<Text>(find.text('Rp150.000/hari'));
    expect(heroValue.style?.fontSize, 38);
    expect(
      heroValue.style?.fontFeatures?.any(
        (feature) => feature.feature == 'tnum',
      ),
      isTrue,
    );
    expect(
      find.ancestor(
        of: find.text('Rp150.000/hari'),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).border != null,
        ),
      ),
      findsNothing,
    );
    expect(find.byKey(const Key('overview-net-worth')), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.text('Kartu kredit'), findsOneWidget);
    expect(find.text('Kesehatan finansial'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('net-worth trend has enough width to remain readable', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    final size = tester.getSize(find.byType(FtSparkline));
    expect(size.width, greaterThan(70));
  });
}
