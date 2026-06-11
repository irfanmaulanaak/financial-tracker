import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:financial_tracker/src/ui/ft_donut.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Regression for the /spend hero: the old MiniDonut subtracted a 1.5 rad
  // gap from every sweep, silently dropping any slice under ~24% of the
  // total. With 7 real categories only 2 arcs survived. FtDonut must render
  // every positive segment — including a 2.2% sliver.
  testWidgets('FtDonut paints all segments, even tiny ones', (tester) async {
    const colors = [
      Color(0xFFFF0000),
      Color(0xFF00FF00),
      Color(0xFF0000FF),
      Color(0xFFFFFF00),
      Color(0xFFFF00FF),
      Color(0xFF00FFFF),
      Color(0xFF000000),
    ];
    // Mirrors the audit household: 35.2 / 26.6 / 15.5 / 12.1 / 5.2 / 3.2 /
    // 2.2 percent.
    const values = [2850000.0, 2150000.0, 1250000.0, 980000.0, 420000.0, 260000.0, 180000.0];
    final key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: key,
            child: FtDonut(
              size: 200,
              thickness: 20,
              animationDuration: Duration.zero,
              segments: [
                for (var i = 0; i < colors.length; i++)
                  FtDonutSegment(value: values[i], color: colors[i]),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    late final ByteData bytes;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    });

    final seen = <int>{};
    for (var i = 0; i < bytes.lengthInBytes; i += 4) {
      final argb = (bytes.getUint8(i + 3) << 24) |
          (bytes.getUint8(i) << 16) |
          (bytes.getUint8(i + 1) << 8) |
          bytes.getUint8(i + 2);
      seen.add(argb);
    }
    for (var i = 0; i < colors.length; i++) {
      expect(
        seen.contains(colors[i].toARGB32()),
        isTrue,
        reason: 'segment $i (${(values[i] / 8090000 * 100).toStringAsFixed(1)}%) '
            'must be painted',
      );
    }
  });
}
