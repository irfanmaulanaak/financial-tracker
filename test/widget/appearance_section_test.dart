import 'package:financial_tracker/src/core/layout_provider.dart';
import 'package:financial_tracker/src/core/theme_provider.dart';
import 'package:financial_tracker/src/features/settings/widgets/appearance_section.dart';
import 'package:financial_tracker/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _harness() {
  return const ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: AppearanceSection()),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('renders Mode, Warna, Menu bawah, Beranda, Liquid Glass',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Tampilan'), findsOneWidget);

    expect(find.text('Mode'), findsOneWidget);
    expect(find.text('Terang'), findsOneWidget);
    expect(find.text('Gelap'), findsOneWidget);

    expect(find.text('Warna'), findsOneWidget);
    for (final p in FtPalette.values) {
      expect(find.text(p.label), findsOneWidget);
    }

    expect(find.text('Menu bawah'), findsOneWidget);
    expect(find.text('Melayang'), findsOneWidget);
    expect(find.text('Menempel'), findsOneWidget);

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Lengkap'), findsOneWidget);
    expect(find.text('Ringkas'), findsOneWidget);

    expect(find.text('Liquid Glass'), findsOneWidget);
  });

  testWidgets('defaults: Terang, Daun, Menempel, Lengkap',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppearanceSection)),
    );
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(container.read(paletteProvider), FtPalette.daun);
    expect(container.read(bottomNavStyleProvider), FtNavStyle.fixed);
    expect(container.read(homeLayoutProvider), FtHomeLayout.lengkap);
    expect(container.read(liquidThemeProvider), false);
  });

  testWidgets('tapping a palette swatch selects that palette', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Laut'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppearanceSection)),
    );
    expect(container.read(paletteProvider), FtPalette.laut);
  });
}
