import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_ring.dart';
import '../../ui/ft_ui.dart';
import '../goals/contribution.dart';
import '../goals/goal.dart';
import '../goals/goal_repository.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household_providers.dart';

final _goalProvider =
    StreamProvider.family<Goal?, ({String hid, String goalId})>((ref, p) {
  return ref.watch(goalRepositoryProvider).watchOne(hid: p.hid, goalId: p.goalId);
});

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final goalAsync = ref.watch(_goalProvider((hid: household.id, goalId: goalId)));

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: goalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (goal) {
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
          return _Body(householdId: household.id, goal: goal);
        },
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.householdId, required this.goal});
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
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          FtSubHeader(
            title: goal.label,
            trailing: FtAddButton(
              tooltip: 'Setor',
              onTap: () => _openContribute(context, ref),
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
                    onPressed: () => _openContribute(context, ref),
                    child: const Text('+ Setor Sekarang'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openContribute(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tambah ke ${goal.label}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final v = Money.parse(ctrl.text) ?? 0;
                if (v <= 0) return;
                Navigator.pop(context, v);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (amount != null) {
      final uid = ref.read(authStateProvider).value?.uid ?? '';
      try {
        await ref
            .read(goalRepositoryProvider)
            .contribute(
              hid: householdId,
              goalId: goal.id,
              amount: amount,
              byUid: uid,
            );
      } catch (e) {
        if (context.mounted) {
          showFtErrorSnack(context, e, prefix: 'Gagal menyetor ke tujuan');
        }
      }
    }
    ctrl.dispose();
  }
}
