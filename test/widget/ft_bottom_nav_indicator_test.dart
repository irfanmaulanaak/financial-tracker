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
            body: SizedBox(
              width: 400,
              height: 80,
              child: FtBottomNav(current: tab),
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

  testWidgets('FtBottomNav renders an AnimatedAlign pill at active tab',
      (tester) async {
    await pumpNav(tester, FtTab.spend);
    // The sliding pill is implemented with AnimatedAlign.
    expect(find.byType(AnimatedAlign), findsOneWidget);
  });

  testWidgets('Pill alignment differs between two active tabs',
      (tester) async {
    await pumpNav(tester, FtTab.home);
    final firstAlign =
        tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment
            as Alignment;
    await pumpNav(tester, FtTab.cards);
    final secondAlign =
        tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment
            as Alignment;
    expect(firstAlign.x, isNot(equals(secondAlign.x)));
  });
}
