import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_refresh.dart';
import '../../../ui/ft_ring.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../../household/household_providers.dart';
import '../../investments/investment.dart';
import '../../investments/investments_repository.dart' show investmentsProvider;
import '../contribution.dart';
import '../goal.dart';
import '../goal_repository.dart';
import '../goals_screen.dart' show fundedGoalsProvider, goalsProvider;
import 'goal_detail_contribute.dart';
import 'goal_funding_sheet.dart';

class GoalDetailBody extends ConsumerWidget {
  const GoalDetailBody({
    super.key,
    required this.householdId,
    required this.goal,
  });
  final String householdId;
  final Goal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pct = (goal.progress * 100).round();
    final remaining = goal.target - goal.current;
    final monthsLeft = goal.monthlyContrib > 0
        ? (remaining / goal.monthlyContrib).ceil()
        : 0;
    final color = parseColor(goal.color);

    final household = ref.watch(currentHouseholdProvider).value;
    final investments =
        ref.watch(investmentsProvider(householdId)).value ??
            const <Investment>[];
    final fundingAsset = household == null
        ? null
        : goalFundingAssetOf(
            goal: goal,
            household: household,
            investments: investments,
          );
    // Goal lain yang berbagi aset sumber dana yang sama (basis proporsional).
    final allGoals =
        ref.watch(fundedGoalsProvider(householdId)).value ?? const <Goal>[];
    final sharedCount = goal.fundingKey == null
        ? 0
        : allGoals.where((g) => g.fundingKey == goal.fundingKey).length;

    // Real contribution history bucketed into the last 8 months.
    final contribsAsync = ref.watch(
      goalContributionsProvider((hid: householdId, goalId: goal.id)),
    );
    const monthsBack = 8;
    final all = contribsAsync.value ?? const <GoalContribution>[];
    final monthly = contributionsByMonth(
      contribs: all,
      monthsBack: monthsBack,
    );
    final monthLabels = monthLabelsForBars(monthsBack: monthsBack);
    final monthlyTotal = monthly.fold<int>(0, (a, b) => a + b);

    return FtAppChrome(
      current: FtTab.goals,
      child: FtRefreshable(
        onRefresh: () async {
          ref.invalidate(currentHouseholdProvider);
          ref.invalidate(goalsProvider(householdId));
          ref.invalidate(investmentsProvider(householdId));
          ref.invalidate(goalContributionsProvider((hid: householdId, goalId: goal.id)));
          await ftRefreshDelay();
        },
        child: ListView(
        padding: const EdgeInsets.only(bottom: kFtFabClearance),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          FtSubHeader(
            title: goal.label,
            trailing: goal.isLinked
                ? null
                : FtAddButton(
                    tooltip: 'Setor',
                    onTap: () => openGoalContribute(
                      context,
                      ref,
                      householdId: householdId,
                      goal: goal,
                    ),
                  ),
          ),
          FtCard(
            margin: const EdgeInsets.fromLTRB(22, 4, 22, 18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FtRing(
                      value: goal.progress,
                      max: 1,
                      size: 140,
                      thickness: 10,
                      color: color,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Eyebrow('Tercapai'),
                          const SizedBox(height: 2),
                          Text(
                            '$pct%',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(fontSize: 32, height: 1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${compactMoney(goal.current)} / ${compactMoney(goal.target)}',
                            style: TextStyle(
                              color: FtColors.ink3,
                              fontSize: 11,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 14),
                FtStatGrid(
                  items: [
                    FtStatItem(
                      label: 'Sisa',
                      value: Money.format(remaining),
                    ),
                    FtStatItem(
                      label: 'Setoran/bln',
                      value: Money.format(goal.monthlyContrib),
                    ),
                    FtStatItem(
                      label: 'Target',
                      value: goal.dueDate != null
                          ? Dates.short(goal.dueDate!)
                          : '-',
                    ),
                  ],
                ),
              ],
            ),
          ),
          FtCard(
            margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
            onTap: () => _changeFunding(context, ref),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Eyebrow('Sumber Dana')),
                    Text(
                      'Ubah',
                      style: TextStyle(
                        color: FtColors.ink3,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (fundingAsset == null)
                  Text(
                    'Manual. Dicatat lewat setoran ke tujuan ini.',
                    style: TextStyle(
                        color: FtColors.ink2, fontSize: 13, height: 1.5),
                  )
                else if (fundingAsset.missing)
                  Text(
                    'Aset sumber dana sudah dihapus. Pilih sumber lain '
                    'atau kembalikan ke manual.',
                    style: TextStyle(
                        color: FtColors.danger, fontSize: 13, height: 1.5),
                  )
                else ...[
                  Row(
                    children: [
                      Icon(Icons.link, size: 14, color: FtColors.ink2),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          fundingAsset.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: FtColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        Money.format(fundingAsset.value),
                        style: TextStyle(
                          color: FtColors.ink2,
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sharedCount > 1
                        ? 'Porsi tujuan ini ${Money.format(goal.current)}. '
                            'Nilai aset dibagi proporsional dengan '
                            '${sharedCount - 1} tujuan lain.'
                        : 'Nilai tujuan mengikuti nilai aset ini secara '
                            'otomatis.',
                    style: TextStyle(
                        color: FtColors.ink2, fontSize: 12, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
          if (!goal.isLinked) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Eyebrow('Setoran 8 Bulan Terakhir'),
          ),
          FtCard(
            margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
            child: monthlyTotal == 0
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'Belum ada riwayat setoran.',
                        style: TextStyle(
                          color: FtColors.ink3,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 0; i < monthly.length; i++) ...[
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: max(
                                    monthly[i] == 0 ? 0 : 6,
                                    (monthly[i] /
                                            max(1, monthly.reduce(max)) *
                                            70),
                                  ),
                                  decoration: BoxDecoration(
                                    color: i == monthly.length - 1
                                        ? color
                                        : color.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  monthLabels[i],
                                  style: TextStyle(
                                      fontSize: 9, color: FtColors.ink3),
                                ),
                              ],
                            ),
                          ),
                          if (i != monthly.length - 1)
                            const SizedBox(width: 6),
                        ],
                      ],
                    ),
                  ),
          ),
          ],
          FtCard(
            margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Proyeksi'),
                const SizedBox(height: 10),
                Text(
                  'Dengan rata-rata setoran ${Money.format(goal.monthlyContrib)} per bulan, tujuan ini tercapai dalam ${monthsLeft > 0 ? monthsLeft : '?'} bulan.',
                  style: TextStyle(
                      color: FtColors.ink2, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Sesuaikan'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: goal.isLinked
                        ? () => _changeFunding(context, ref)
                        : () => openGoalContribute(
                              context,
                              ref,
                              householdId: householdId,
                              goal: goal,
                            ),
                    child: Text(goal.isLinked
                        ? 'Ubah Sumber Dana'
                        : '+ Setor Sekarang'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _changeFunding(BuildContext context, WidgetRef ref) async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;
    final investments =
        ref.read(investmentsProvider(householdId)).value ??
            const <Investment>[];
    final choice = await showGoalFundingSheet(
      context,
      household: household,
      investments: investments,
      currentKey: goal.fundingKey,
    );
    if (choice == null) return;
    try {
      await ref.read(goalRepositoryProvider).setFunding(
            hid: householdId,
            goalId: goal.id,
            type: choice.type,
            id: choice.id,
          );
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal mengubah sumber dana');
      }
    }
  }
}
