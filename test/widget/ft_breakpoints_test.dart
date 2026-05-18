import 'package:financial_tracker/src/ui/ft_breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ftBreakpointForWidth returns the right tier at each threshold', () {
    expect(ftBreakpointForWidth(0), FtBreakpoint.compact);
    expect(ftBreakpointForWidth(359), FtBreakpoint.compact);
    expect(ftBreakpointForWidth(599), FtBreakpoint.compact);
    expect(ftBreakpointForWidth(600), FtBreakpoint.medium);
    expect(ftBreakpointForWidth(904), FtBreakpoint.medium);
    expect(ftBreakpointForWidth(905), FtBreakpoint.expanded);
    expect(ftBreakpointForWidth(1239), FtBreakpoint.expanded);
    expect(ftBreakpointForWidth(1240), FtBreakpoint.large);
    expect(ftBreakpointForWidth(1920), FtBreakpoint.large);
  });

  testWidgets('context.bp reads MediaQuery width', (tester) async {
    late FtBreakpoint observed;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 1000)),
        child: Builder(
          builder: (ctx) {
            observed = ctx.bp;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(observed, FtBreakpoint.medium);
  });

  testWidgets('context.isAtLeastMedium is false on phone, true on tablet',
      (tester) async {
    late bool phoneAtLeastMedium;
    late bool tabletAtLeastMedium;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: Builder(
          builder: (ctx) {
            phoneAtLeastMedium = ctx.isAtLeastMedium;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1024, 768)),
        child: Builder(
          builder: (ctx) {
            tabletAtLeastMedium = ctx.isAtLeastMedium;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(phoneAtLeastMedium, isFalse);
    expect(tabletAtLeastMedium, isTrue);
  });
}
