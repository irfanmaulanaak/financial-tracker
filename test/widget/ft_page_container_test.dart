import 'package:financial_tracker/src/ui/ft_page_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<Size> measureBody(WidgetTester tester, Size screen) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screen),
          child: FtPageContainer(
            child: SizedBox(
              key: key,
              width: double.infinity,
              height: 100,
            ),
          ),
        ),
      ),
    );
    final box = key.currentContext!.findRenderObject() as RenderBox;
    return box.size;
  }

  testWidgets('FtPageContainer is full-width on compact screens',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final size = await measureBody(tester, const Size(360, 800));
    expect(size.width, 360);
  });

  testWidgets('FtPageContainer constrains width on medium screens',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final size = await measureBody(tester, const Size(800, 1000));
    expect(size.width, lessThanOrEqualTo(560));
  });

  testWidgets('FtPageContainer caps at large breakpoint default (720)',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    final size = await measureBody(tester, const Size(1920, 1080));
    expect(size.width, lessThanOrEqualTo(720));
  });
}
