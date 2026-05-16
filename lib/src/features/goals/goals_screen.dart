import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import 'goal.dart';
import 'goal_repository.dart';
import 'widgets/goal_card.dart';
import 'widgets/goal_edit_sheet.dart';

final goalsProvider = StreamProvider.family<List<Goal>, String>((ref, hid) {
  return ref.watch(goalRepositoryProvider).watchAll(hid);
});

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    if (household == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final goalsAsync = ref.watch(goalsProvider(household.id));

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (goals) {
          final totalTarget = goals.fold<int>(0, (a, b) => a + b.target);
          final totalCurrent = goals.fold<int>(0, (a, b) => a + b.current);
          return FtAppChrome(
            current: FtTab.goals,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                FtSubHeader(
                  title: 'Tujuan',
                  trailing: FtAddButton(
                    tooltip: 'Tambah tujuan',
                    onTap: () =>
                        _openSheet(context, ref, household.id, user.uid),
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
                        style: const TextStyle(
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Belum ada tujuan.\nMis. dana darurat, liburan, beli rumah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: FtColors.ink3),
                      ),
                    ),
                  )
                else
                  for (final g in goals)
                    GoalCard(
                      goal: g,
                      ownerLabel: g.ownerId != null
                          ? household.memberOf(g.ownerId!)?.displayName ?? '-'
                          : 'Bersama',
                      onContribute: () =>
                          _openContributeSheet(context, ref, household.id, g),
                      onDelete: () =>
                          _confirmDelete(context, ref, household.id, g),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    String hid,
    String currentUid,
  ) async {
    final result = await showModalBottomSheet<GoalDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GoalEditSheet(currentUid: currentUid),
    );
    if (result == null) return;
    await ref
        .read(goalRepositoryProvider)
        .add(
          hid: hid,
          label: result.label,
          target: result.target,
          dueDate: result.dueDate,
          monthlyContrib: result.monthlyContrib,
          color: result.color,
          icon: result.icon,
          scope: result.scope,
          ownerId: result.ownerId,
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(ctrl.text);
                if (v == null || v <= 0) return;
                Navigator.pop(context, v);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (amount != null) {
      await ref
          .read(goalRepositoryProvider)
          .contribute(hid: hid, goalId: goal.id, amount: amount);
    }
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
      await ref.read(goalRepositoryProvider).delete(hid: hid, goalId: goal.id);
    }
  }
}
