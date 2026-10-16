import 'package:financial_tracker/src/features/goals/goal.dart';
import 'package:financial_tracker/src/features/goals/widgets/goal_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Goal _goal({DateTime? dueDate, int monthlyContrib = 2000000}) => Goal(
      id: 'g1',
      label: 'Dana Darurat',
      target: 60000000,
      current: 43000000,
      dueDate: dueDate,
      monthlyContrib: monthlyContrib,
      icon: 'savings',
      color: '#10B981',
      scope: GoalScope.shared,
      ownerId: null,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  // Harness mirrors GoalsScreen: card sits inside a ReorderableListView with
  // a delayed (hold-to-lift) drag listener, so long-press belongs to reorder.
  Widget harness({required VoidCallback onDelete, Goal? goal}) => MaterialApp(
        home: Scaffold(
          body: ReorderableListView(
            buildDefaultDragHandles: false,
            onReorder: (_, _) {},
            children: [
              ReorderableDelayedDragStartListener(
                key: const ValueKey('g1'),
                index: 0,
                child: GoalCard(
                  goal: goal ?? _goal(),
                  ownerLabel: 'Bersama',
                  onContribute: () {},
                  onDelete: onDelete,
                ),
              ),
            ],
          ),
        ),
      );

  // Long-press is reserved for hold-to-reorder on the Tujuan list, so delete
  // must live in the card's ⋯ menu (regression for the gesture conflict).
  testWidgets('long-press lifts for reorder instead of deleting',
      (tester) async {
    var deleted = false;
    await tester.pumpWidget(harness(onDelete: () => deleted = true));

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Dana Darurat')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(deleted, isFalse);
  });

  testWidgets('delete lives in the card menu', (tester) async {
    var deleted = false;
    await tester.pumpWidget(harness(onDelete: () => deleted = true));

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  // Regression: the tip used to always divide the remaining amount by a flat
  // 6 months, ignoring the actual due date (goal_card.dart ~line 44).
  group('off-track tip uses the real months left to the due date', () {
    // remaining = 60.000.000 - 43.000.000 = 17.000.000; over 6 months that's
    // 2.833.334/bln (ceil) — only the day-of-month component is dropped, so
    // this stays exactly 6 months regardless of when the suite runs.
    DateTime sixMonthsOut() {
      final now = DateTime.now();
      return DateTime(now.year, now.month + 6, 1);
    }

    testWidgets('shows a boosted amount when the plan is below what is required',
        (tester) async {
      await tester.pumpWidget(harness(
        onDelete: () {},
        goal: _goal(dueDate: sixMonthsOut(), monthlyContrib: 2000000),
      ));

      expect(find.textContaining('Naikkan ke Rp2,8 jt/bln agar tepat waktu.'),
          findsOneWidget);
    });

    testWidgets('hides the tip once the plan already meets the due date',
        (tester) async {
      await tester.pumpWidget(harness(
        onDelete: () {},
        goal: _goal(dueDate: sixMonthsOut(), monthlyContrib: 3000000),
      ));

      expect(find.textContaining('Naikkan ke'), findsNothing);
    });

    testWidgets('hides the tip when there is no due date', (tester) async {
      await tester.pumpWidget(harness(
        onDelete: () {},
        goal: _goal(dueDate: null, monthlyContrib: 100),
      ));

      expect(find.textContaining('Naikkan ke'), findsNothing);
    });
  });
}
