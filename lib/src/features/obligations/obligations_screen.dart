import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import 'obligation.dart';
import 'obligation_repository.dart';
import 'obligation_sheets.dart';

class ObligationsScreen extends ConsumerWidget {
  const ObligationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return Scaffold(
        backgroundColor: FtColors.bg,
        body: const FtSkeletonListView(count: 5),
      );
    }
    final obligations =
        ref.watch(obligationsProvider).value ?? const <Obligation>[];
    final active = obligations.where((o) => !o.isComplete).toList();
    final complete = obligations.where((o) => o.isComplete).toList();
    final totalMonthly = ref.watch(activeObligationsMonthlyProvider);
    final canWrite = ref.watch(canWriteAllProvider);

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        bottom: false,
        child: FtPageContainer(
          child: FtRefreshable(
            onRefresh: () async {
              ref.invalidate(obligationsProvider);
              await ftRefreshDelay();
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 40),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                const FtSubHeader(title: 'Cicilan Tetap'),
                FtCard(
                  margin: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Total cicilan / bulan'),
                      const SizedBox(height: 4),
                      Text(
                        Money.format(totalMonthly),
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ),
                if (obligations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          size: 48,
                          color: FtColors.ink4,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Belum ada cicilan tetap.',
                          style: TextStyle(color: FtColors.ink3, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                if (active.isNotEmpty) ...[
                  const _SectionLabel('Berjalan'),
                  for (final obligation in active)
                    _ObligationTile(obligation: obligation, canWrite: canWrite),
                ],
                if (complete.isNotEmpty) ...[
                  const _SectionLabel('Selesai'),
                  for (final obligation in complete)
                    _ObligationTile(
                      obligation: obligation,
                      canWrite: canWrite,
                      dimmed: true,
                    ),
                ],
                if (canWrite)
                  FtDashedAdd(
                    margin: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                    label: 'Tambah cicilan tetap',
                    onTap: () => ObligationFormSheet.show(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
      child: Eyebrow(text),
    );
  }
}

class _ObligationTile extends ConsumerWidget {
  const _ObligationTile({
    required this.obligation,
    required this.canWrite,
    this.dimmed = false,
  });

  final Obligation obligation;
  final bool canWrite;
  final bool dimmed;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus "${obligation.label}"?'),
        content: const Text('Riwayat cicilan ini akan dihapus.'),
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
    if (confirmed != true || !context.mounted) return;
    final hid = ref.read(currentHouseholdProvider).value?.id;
    if (hid == null) return;
    try {
      await ref
          .read(obligationRepositoryProvider)
          .delete(hid: hid, obligationId: obligation.id);
      FtHaptics.success();
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menghapus cicilan');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = obligation;
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      padding: const EdgeInsets.all(14),
      child: Opacity(
        opacity: dimmed ? 0.55 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    o.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (canWrite)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        ObligationFormSheet.show(context, initial: o);
                      } else {
                        _delete(context, ref);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
              ],
            ),
            Text(
              '${Money.format(o.monthly)}/bulan',
              style: TextStyle(
                color: FtColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${o.monthsPaid}/${o.monthsTotal} bulan · jatuh tempo tanggal ${o.dueDay}',
              style: TextStyle(color: FtColors.ink3, fontSize: 11),
            ),
            const SizedBox(height: 8),
            FtProgressBar(
              value: o.monthsPaid,
              max: o.monthsTotal,
              color: ftProgressColor(o.monthsPaid, o.monthsTotal),
              height: 3,
            ),
            if (o.outstandingPrincipal != null) ...[
              const SizedBox(height: 7),
              Text(
                'Sisa pokok ${Money.format(o.outstandingPrincipal!)}',
                style: TextStyle(color: FtColors.ink3, fontSize: 11),
              ),
            ],
            if (canWrite && !o.isComplete) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => PayObligationSheet.show(context, o),
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 16,
                  ),
                  label: const Text('Bayar 1 bulan'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
