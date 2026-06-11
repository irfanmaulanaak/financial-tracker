import 'package:financial_tracker/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Const widget that reads FtColors statically — no Theme dependency, so the
/// framework never rebuilds it on a theme flip by itself. This mirrors the
/// many const subtrees across the app.
class _StaticColorBox extends StatelessWidget {
  const _StaticColorBox();

  @override
  Widget build(BuildContext context) => ColoredBox(color: FtColors.bg);
}

void main() {
  tearDown(() => FtColors.setBrightness(Brightness.light));

  testWidgets('ftRebuildAllWidgets repaints static FtColors consumers',
      (tester) async {
    FtColors.setBrightness(Brightness.light);
    final lightBg = FtColors.bg;

    await tester.pumpWidget(const MaterialApp(home: _StaticColorBox()));

    ColoredBox box() => tester.widget<ColoredBox>(find.descendant(
          of: find.byType(_StaticColorBox),
          matching: find.byType(ColoredBox),
        ));
    expect(box().color, lightBg);

    // Flip brightness without forcing a rebuild: stale color sticks (the bug
    // that used to require a manual refresh).
    FtColors.setBrightness(Brightness.dark);
    final darkBg = FtColors.bg;
    expect(darkBg, isNot(lightBg));
    await tester.pump();
    expect(box().color, lightBg,
        reason: 'const subtree must not rebuild on its own');

    // The fix: mark the whole tree dirty, state preserved.
    ftRebuildAllWidgets();
    await tester.pump();
    expect(box().color, darkBg);
  });
}
