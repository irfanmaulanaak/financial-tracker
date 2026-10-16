import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/providers.dart';
import '../../../ui/ft_celebrate.dart';
import '../../../ui/ft_ui.dart';
import '../goal.dart';
import '../goal_repository.dart';

/// Bottom sheet "+ Setor" untuk satu tujuan manual. Mencatat setoran lalu
/// merayakan milestone 50%/100% bila baru terlewati.
Future<void> openGoalContribute(
  BuildContext context,
  WidgetRef ref, {
  required String householdId,
  required Goal goal,
}) async {
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
      // Perayaan milestone — sekali, tepat di momen terlewati.
      final milestone = goalMilestoneCrossed(
        before: goal.current,
        after: goal.current + amount,
        target: goal.target,
      );
      if (context.mounted) {
        FtCelebrate.show(
          context,
          message: switch (milestone) {
            100 => '"${goal.label}" tercapai.',
            50 => 'Setengah jalan ke "${goal.label}".',
            _ => 'Setoran tersimpan',
          },
          hold: milestone != null
              ? const Duration(milliseconds: 1400)
              : const Duration(milliseconds: 600),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menyetor ke tujuan');
      }
    }
  }
  ctrl.dispose();
}
