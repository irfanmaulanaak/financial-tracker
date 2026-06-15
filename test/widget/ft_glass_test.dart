import 'package:financial_tracker/src/theme.dart';
import 'package:financial_tracker/src/ui/ft_glass.dart';
import 'package:financial_tracker/src/ui/ft_glass_fx.dart';
import 'package:financial_tracker/src/ui/ft_liquid_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool highContrast = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(highContrast: highContrast),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  tearDown(() => FtColors.setLiquid(false));

  testWidgets('liquid OFF tanpa blur fallback → solid, tanpa BackdropFilter',
      (tester) async {
    FtColors.setLiquid(false);
    await tester.pumpWidget(_host(
      FtGlass(
        borderRadius: BorderRadius.circular(20),
        child: const SizedBox(width: 100, height: 40),
      ),
    ));
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('liquid OFF dengan fallbackBlurSigma → BackdropFilter (paritas nav klasik)',
      (tester) async {
    FtColors.setLiquid(false);
    await tester.pumpWidget(_host(
      FtGlass(
        borderRadius: BorderRadius.circular(28),
        fallbackAlpha: 0.88,
        fallbackBlurSigma: 18,
        child: const SizedBox(width: 100, height: 40),
      ),
    ));
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('liquid ON → jalur glass (BackdropFilter) aktif',
      (tester) async {
    FtColors.setLiquid(true);
    await tester.pumpWidget(_host(
      FtGlass(
        borderRadius: BorderRadius.circular(20),
        child: const SizedBox(width: 100, height: 40),
      ),
    ));
    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('liquid ON + high contrast → fallback solid (a11y)',
      (tester) async {
    FtColors.setLiquid(true);
    await tester.pumpWidget(_host(
      FtGlass(
        borderRadius: BorderRadius.circular(20),
        child: const SizedBox(width: 100, height: 40),
      ),
      highContrast: true,
    ));
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('lens paints on first frame without deferred origin state',
      (tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 20),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(
      LiquidScene(
        controller: controller,
        child: GlassLensLayer(borderRadius: BorderRadius.circular(20)),
      ),
    ));

    expect(
      find.descendant(
        of: find.byType(GlassLensLayer),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
  });
}
