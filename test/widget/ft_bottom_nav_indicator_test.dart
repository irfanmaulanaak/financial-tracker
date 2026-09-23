import 'package:financial_tracker/src/theme.dart';
import 'package:financial_tracker/src/ui/ft_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pumpNav(WidgetTester tester, FtTab tab) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            backgroundColor: FtColors.bg,
            body: Center(
              child: SizedBox(
                width: 358,
                child: FtBottomNav(current: tab, showAction: false),
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          theme: buildTheme(Brightness.light),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('Only the active tab shows its label', (tester) async {
    await pumpNav(tester, FtTab.spend);
    expect(find.text('Belanja'), findsOneWidget);
    expect(find.text('Beranda'), findsNothing);
    expect(find.text('Utang'), findsNothing);
  });

  testWidgets('Label follows the active tab', (tester) async {
    await pumpNav(tester, FtTab.cards);
    expect(find.text('Utang'), findsOneWidget);
    expect(find.text('Belanja'), findsNothing);
  });
}
