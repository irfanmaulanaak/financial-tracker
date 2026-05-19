import 'package:financial_tracker/src/ui/ft_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FtSkeletonListView renders the requested number of tiles',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FtSkeletonListView(count: 4),
        ),
      ),
    );
    // The shimmer animates continuously, so we pump frames instead of settle.
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(FtSkeletonTile), findsNWidgets(4));
  });

  testWidgets('FtSkeletonTile composes circle + 2 lines + trailing',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FtSkeletonTile(),
        ),
      ),
    );
    expect(find.byType(FtSkeletonCircle), findsOneWidget);
    expect(find.byType(FtSkeletonLine), findsNWidgets(3));
  });
}
