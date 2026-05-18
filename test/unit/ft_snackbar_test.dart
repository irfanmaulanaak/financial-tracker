import 'package:financial_tracker/src/ui/ft_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showFtErrorSnack renders prefix + error message', (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    showFtErrorSnack(capturedContext, 'boom', prefix: 'Gagal bayar');
    await tester.pump();

    expect(find.text('Gagal bayar: boom'), findsOneWidget);
  });

  testWidgets('showFtErrorSnack accepts Object error without prefix', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) {
              capturedContext = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final err = StateError('card_has_balance');
    showFtErrorSnack(capturedContext, err);
    await tester.pump();

    expect(find.textContaining('card_has_balance'), findsOneWidget);
  });
}
