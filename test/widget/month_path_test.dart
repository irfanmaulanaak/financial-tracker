import 'package:financial_tracker/src/features/home/eling/eling_painter.dart';
import 'package:financial_tracker/src/features/home/eling/eling_scene.dart';
import 'package:financial_tracker/src/features/home/eling/month_path.dart';
import 'package:financial_tracker/src/features/home/eling/month_path_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Widget child, {bool reduce = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 345, child: child),
        ),
      ),
    );

MonthTrackPainter _trackPainter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .whereType<MonthTrackPainter>()
    .first;

void main() {
  setUp(() {
    ElingSession.monthPathsEntered.clear();
  });

  testWidgets('shows the correct filled-dot fraction for monthsPaid/monthsTotal',
      (tester) async {
    await tester.pumpWidget(_harness(
      MonthPathEling(
        entranceId: 'c1',
        monthsTotal: 12,
        monthsPaid: 3,
        startedAt: DateTime(2026, 8, 10),
      ),
      reduce: true,
    ));
    await tester.pump();

    final painter = _trackPainter(tester);
    expect(painter.monthsTotal, 12);
    expect(painter.paidFraction, closeTo(3 / 12, 0.0001));
  });

  testWidgets('a monthsPaid bump shows the "Mantap!" bubble with months left',
      (tester) async {
    await tester.pumpWidget(_harness(MonthPathEling(
      entranceId: 'c1',
      monthsTotal: 12,
      monthsPaid: 3,
      startedAt: DateTime(2026, 8, 10),
    )));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_harness(MonthPathEling(
      entranceId: 'c1',
      monthsTotal: 12,
      monthsPaid: 4,
      startedAt: DateTime(2026, 8, 10),
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1150)); // curl+roll+stand
    await tester.pump(const Duration(milliseconds: 150)); // bubble pop-in

    expect(find.textContaining('Mantap! Tinggal 8 bulan lagi.'), findsOneWidget);
  });

  testWidgets('the static mini version draws no Eling', (tester) async {
    await tester.pumpWidget(
        _harness(const MonthPathMini(monthsTotal: 12, monthsPaid: 3)));
    await tester.pump();

    final hasEling = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<ElingPainter>()
        .isNotEmpty;
    expect(hasEling, isFalse);

    final painter = _trackPainter(tester);
    expect(painter.monthsTotal, 12);
    expect(painter.paidFraction, closeTo(3 / 12, 0.0001));
  });

  testWidgets('a completed (showEling: false) tile draws no Eling either',
      (tester) async {
    await tester.pumpWidget(_harness(
      MonthPathEling(
        entranceId: 'c2',
        monthsTotal: 6,
        monthsPaid: 6,
        startedAt: DateTime(2026, 6, 1),
        showEling: false,
      ),
      reduce: true,
    ));
    await tester.pump();

    final hasEling = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<ElingPainter>()
        .isNotEmpty;
    expect(hasEling, isFalse);
  });
}
