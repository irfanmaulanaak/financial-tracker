import 'package:financial_tracker/src/features/goals/goal.dart';
import 'package:financial_tracker/src/features/goals/widgets/goal_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Goal _goal() => Goal(
      id: 'g1',
      label: 'Dana Darurat',
      target: 60000000,
      current: 43000000,
      dueDate: null,
      monthlyContrib: 2000000,
      icon: 'savings',
      color: '#10B981',
      scope: GoalScope.shared,
      ownerId: null,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  // Harness mirrors GoalsScreen: card sits inside a ReorderableListView with
  // a delayed (hold-to-lift) drag listener, so long-press belongs to reorder.
  Widget harness({required VoidCallback onDelete}) => MaterialApp(
        home: Scaffold(
          body: ReorderableListView(
            buildDefaultDragHandles: false,
            onReorder: (_, _) {},
            children: [
              ReorderableDelayedDragStartListener(
                key: const ValueKey('g1'),
                index: 0,
                child: GoalCard(
                  goal: _goal(),
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
}
