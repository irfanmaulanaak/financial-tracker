import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../goals/goal.dart';
import '../goals/goals_screen.dart' show fundedGoalsProvider;
import '../household/household_providers.dart';
import 'widgets/goal_detail_body.dart';

export 'widgets/goal_detail_body.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final goalsAsync = ref.watch(fundedGoalsProvider(household.id));

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (goals) {
          Goal? goal;
          for (final g in goals) {
            if (g.id == goalId) {
              goal = g;
              break;
            }
          }
          if (goal == null) {
            return FtAppChrome(
              current: FtTab.goals,
              child: Column(
                children: [
                  const FtSubHeader(title: 'Tujuan'),
                  Expanded(
                    child: Center(
                      child: Text('Tujuan tidak ditemukan.',
                          style: TextStyle(color: FtColors.ink3)),
                    ),
                  ),
                ],
              ),
            );
          }
          return GoalDetailBody(householdId: household.id, goal: goal);
        },
      ),
    );
  }
}
