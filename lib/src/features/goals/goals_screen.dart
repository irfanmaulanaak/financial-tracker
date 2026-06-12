import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/goal_funding.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import '../investments/investment.dart';
import '../investments/investments_repository.dart' show investmentsProvider;
import 'goal.dart';
import 'goal_repository.dart';
import 'widgets/goal_card.dart';
import 'widgets/goal_funding_sheet.dart';

final goalsProvider = StreamProvider.family<List<Goal>, String>((ref, hid) {
  return ref.watch(goalRepositoryProvider).watchAll(hid);
});

/// Goals dengan `current` linked goals SUDAH dihitung dari nilai asetnya
/// (proporsional terhadap target bila satu aset dipakai beberapa goal).
/// Semua layar yang menampilkan progress goal harus pakai ini, bukan
/// [goalsProvider] mentah.
final fundedGoalsProvider =
    Provider.family<AsyncValue<List<Goal>>, String>((ref, hid) {
  final goalsAsync = ref.watch(goalsProvider(hid));
  final household = ref.watch(currentHouseholdProvider).value;
  final investments =
      ref.watch(investmentsProvider(hid)).value ?? const <Investment>[];
  return goalsAsync.whenData((goals) {
    final assetValues = <String, int>{
      if (household != null)
        for (final a in household.savingsAccounts)
          goalFundingKey('savings', a.id): a.value,
      for (final inv in investments)
        goalFundingKey('investment', inv.id): inv.currentValue,
    };
    final alloc = allocateLinkedGoals(
      goals: [
        for (final g in goals)
          (id: g.id, target: g.target, fundingKey: g.fundingKey),
      ],
      assetValues: assetValues,
    );
    return [
      for (final g in goals)
        g.isLinked ? g.withCurrent(alloc[g.id] ?? 0) : g,
    ];
  });
});

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    if (household == null || user == null) {
      return Scaffold(
        backgroundColor: FtColors.bg,
        body: const FtSkeletonListView(count: 4, tileHeight: 110),
      );
    }
    final goalsAsync = ref.watch(fundedGoalsProvider(household.id));
    final investments =
        ref.watch(investmentsProvider(household.id)).value ??
            const <Investment>[];

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: goalsAsync.when(
        loading: () => const FtSkeletonListView(count: 4, tileHeight: 110),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (goals) {
          final totalTarget = goals.fold<int>(0, (a, b) => a + b.target);
          final totalCurrent = goals.fold<int>(0, (a, b) => a + b.current);
          return FtAppChrome(
            current: FtTab.goals,
            child: FtRefreshable(
              onRefresh: () async {
                ref.invalidate(currentHouseholdProvider);
                ref.invalidate(goalsProvider(household.id));
                await ftRefreshDelay();
              },
              child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                FtSubHeader(
                  title: 'Tujuan',
                  trailing: FtAddButton(
                    tooltip: 'Tujuan baru',
                    onTap: () => context.push('/goals/new'),
                  ),
                ),
                FtCard(
                  margin: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Tujuan Finansial'),
                      const SizedBox(height: 6),
                      Text(
                        Money.format(totalCurrent),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'dari ${Money.format(totalTarget)} target',
                        style: TextStyle(
                          color: FtColors.ink3,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FtProgressBar(
                        value: totalCurrent,
                        max: totalTarget <= 0 ? 1 : totalTarget,
                        color: FtColors.moss,
                        height: 6,
                      ),
                    ],
                  ),
                ),
                if (goals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Text(
                        'Belum ada tujuan.\nMis. dana darurat, liburan, beli rumah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: FtColors.ink3),
                      ),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: goals.length,
                    onReorderStart: (_) => FtHaptics.tap(),
                    onReorder: (oldIndex, newIndex) =>
                        _onReorder(ref, household.id, goals, oldIndex, newIndex),
                    proxyDecorator: (child, _, _) => Material(
                      color: Colors.transparent,
                      child: child,
                    ),
                    itemBuilder: (context, i) {
                      final g = goals[i];
                      // Delayed (hold-then-drag) so normal scrolling over the
                      // cards doesn't lift them — press and hold to reorder.
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(g.id),
                        index: i,
                        child: GoalCard(
                          goal: g,
                          ownerLabel: g.ownerId != null
                              ? prettyName(household
                                      .memberOf(g.ownerId!)
                                      ?.displayName ??
                                  '-')
                              : 'Bersama',
                          fundingAsset: goalFundingAssetOf(
                            goal: g,
                            household: household,
                            investments: investments,
                          ),
                          onContribute: () => _openContributeSheet(
                              context, ref, household.id, g),
                          onDelete: () =>
                              _confirmDelete(context, ref, household.id, g),
                        ),
                      );
                    },
                  ),
                FtDashedAdd(
                  margin: const EdgeInsets.fromLTRB(22, 8, 22, 4),
                  label: 'Tambah tujuan',
                  onTap: () => context.push('/goals/new'),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  void _onReorder(
    WidgetRef ref,
    String hid,
    List<Goal> goals,
    int oldIndex,
    int newIndex,
  ) {
    FtHaptics.tap();
    final ids = reorderIds(
      ids: goals.map((g) => g.id).toList(),
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    // ignore: discarded_futures
    ref.read(goalRepositoryProvider).reorderGoals(
          hid: hid,
          orderedIds: ids,
        );
  }

  Future<void> _openContributeSheet(
    BuildContext context,
    WidgetRef ref,
    String hid,
    Goal goal,
  ) async {
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
          children: [
            Text(
              'Tambah ke ${goal.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
              hid: hid,
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String hid,
    Goal goal,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus "${goal.label}"?'),
        content: const Text('Tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref
            .read(goalRepositoryProvider)
            .delete(hid: hid, goalId: goal.id);
      } catch (e) {
        if (context.mounted) {
          showFtErrorSnack(context, e, prefix: 'Gagal menghapus tujuan');
        }
      }
    }
  }
}
