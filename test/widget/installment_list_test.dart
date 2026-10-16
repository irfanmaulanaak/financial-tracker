import 'package:financial_tracker/src/features/cards/credit_card.dart';
import 'package:financial_tracker/src/features/cards/widgets/installment_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Installment _installment({
  required String id,
  required int monthly,
  required int monthsTotal,
  int monthsPaid = 0,
  String label = '',
}) {
  return Installment(
    id: id,
    cardId: 'card-1',
    expenseId: 'expense-$id',
    label: label,
    total: monthly * monthsTotal,
    monthly: monthly,
    monthsTotal: monthsTotal,
    monthsPaid: monthsPaid,
    startedAt: DateTime(2026),
  );
}

Future<void> _pump(WidgetTester tester, List<Installment> items) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cardInstallmentsProvider((hid: 'h1', cardId: 'card-1'))
            .overrideWith((ref) => Stream.value(items)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: CardInstallmentsInline(hid: 'h1', cardId: 'card-1'),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // Regression: a one-time (Lunas, 1-month) purchase used to be counted as
  // an active cicilan — "N cicilan aktif" line also summed its monthly
  // amount, and it showed a meaningless "0/1 bulan" progress bar.
  testWidgets('a one-time purchase is not counted as a cicilan',
      (tester) async {
    await _pump(tester, [
      _installment(id: 'hotel', monthly: 4330000, monthsTotal: 1, label: 'Hotel Amarta Hills'),
      _installment(id: 'tv', monthly: 1500000, monthsTotal: 6, monthsPaid: 2, label: 'TV'),
    ]);

    expect(find.textContaining('1 cicilan aktif'), findsOneWidget);
    expect(find.textContaining('Rp1.500.000/bln'), findsWidgets);
    expect(find.textContaining('3 cicilan aktif'), findsNothing);
    expect(find.textContaining('belum ditagih'), findsOneWidget);
  });

  testWidgets('only one-time purchases: no cicilan line, just belum ditagih',
      (tester) async {
    await _pump(tester, [
      _installment(id: 'hotel', monthly: 4330000, monthsTotal: 1),
    ]);

    expect(find.textContaining('cicilan aktif'), findsNothing);
    expect(find.textContaining('1 belum ditagih'), findsOneWidget);
  });

  testWidgets('completed installments are excluded entirely', (tester) async {
    await _pump(tester, [
      _installment(id: 'done', monthly: 500000, monthsTotal: 3, monthsPaid: 3),
    ]);

    expect(find.textContaining('cicilan aktif'), findsNothing);
    expect(find.textContaining('belum ditagih'), findsNothing);
  });
}
