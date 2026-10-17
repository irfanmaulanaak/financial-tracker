import 'package:financial_tracker/src/features/goals/goal.dart';
import 'package:financial_tracker/src/features/goals/widgets/goal_progress_hero.dart';
import 'package:financial_tracker/src/features/home/eling/eling_scene.dart';
import 'package:financial_tracker/src/features/home/eling/eling_scene_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Goal _goal({
  int current = 120000000,
  int target = 200000000,
  int monthlyContrib = 16000000,
}) =>
    Goal(
      id: 'g1',
      label: 'Mobil',
      target: target,
      current: current,
      dueDate: null,
      monthlyContrib: monthlyContrib,
      icon: 'directions_car',
      color: '#10B981',
      scope: GoalScope.shared,
      ownerId: null,
      createdAt: DateTime(2026, 1, 1),
    );

Widget _harness(Goal goal, {bool reduce = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 393, child: GoalProgressHero(goal: goal)),
        ),
      ),
    );

String _bubbleText(WidgetTester tester) =>
    tester.widget<ElingSpeechBubble>(find.byType(ElingSpeechBubble)).text;

bool _showsPercent(WidgetTester tester, String text) => tester
    .widgetList<RichText>(find.byType(RichText))
    .any((r) => r.text.toPlainText() == text);

void main() {
  setUp(() {
    ElingSession.goalsEntered.clear();
  });

  testWidgets('reduce motion shows the final percent and bubble at once',
      (tester) async {
    await tester.pumpWidget(_harness(_goal(), reduce: true));
    await tester.pump();

    expect(_showsPercent(tester, '60%'), isTrue);
    expect(
      _bubbleText(tester),
      'Sudah 60%! Kurang Rp80 jt lagi.\nSekitar 5 bulan lagi sampai.',
    );
  });

  testWidgets('settles at the right percent and bubble after the entrance',
      (tester) async {
    await tester.pumpWidget(_harness(_goal()));
    await tester.pump();
    // Entrance (2500ms) then let the stand/bubble callback settle.
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();

    expect(_showsPercent(tester, '60%'), isTrue);
    expect(
      _bubbleText(tester),
      'Sudah 60%! Kurang Rp80 jt lagi.\nSekitar 5 bulan lagi sampai.',
    );
  });

  testWidgets('0 progress invites the first deposit', (tester) async {
    await tester.pumpWidget(
        _harness(_goal(current: 0, monthlyContrib: 0), reduce: true));
    await tester.pump();

    expect(_showsPercent(tester, '0%'), isTrue);
    expect(_bubbleText(tester), 'Yuk mulai setor pertama.');
  });

  testWidgets('a progress increase replays the roll and updates the bubble',
      (tester) async {
    await tester.pumpWidget(_harness(_goal(current: 60000000))); // 30%
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump();
    expect(_showsPercent(tester, '30%'), isTrue);

    // A contribution lands while the screen is open: same goal id, new total.
    await tester.pumpWidget(_harness(_goal(current: 120000000))); // 60%
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump();

    expect(_showsPercent(tester, '60%'), isTrue);
    expect(
      _bubbleText(tester),
      'Sudah 60%! Kurang Rp80 jt lagi.\nSekitar 5 bulan lagi sampai.',
    );
  });
}
