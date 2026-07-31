import 'package:financial_tracker/src/features/auth/auth_legal_links.dart';
import 'package:financial_tracker/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/link.dart';

void main() {
  testWidgets('shows public terms and privacy links', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const Scaffold(body: AuthLegalLinks()),
      ),
    );

    expect(find.text('Ketentuan Layanan'), findsOneWidget);
    expect(find.text('Kebijakan Privasi'), findsOneWidget);

    final links = tester.widgetList<Link>(find.byType(Link)).toList();
    expect(links.map((link) => link.uri.toString()), [
      'https://finsist.site/tos',
      'https://finsist.site/policy',
    ]);
  });
}
