import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import 'debt.dart';
import 'debt_repository.dart';
import 'widgets/debts_sheets.dart';
import 'widgets/debts_tiles.dart';

export 'widgets/debts_sheets.dart';
export 'widgets/debts_tiles.dart';

/// "Utang & Piutang" — ledger sederhana untuk pinjaman keluarga.
/// Catatan murni: tidak mengubah saldo rekening.
class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return Scaffold(
        backgroundColor: FtColors.bg,
        body: const FtSkeletonListView(count: 5),
      );
    }
    final debts = ref.watch(debtsProvider).value ?? const <Debt>[];
    final canTxn = ref.watch(canRecordTxnProvider);

    final utangOpen =
        debts.where((d) => d.type == DebtType.utang && !d.settled).toList();
    final piutangOpen =
        debts.where((d) => d.type == DebtType.piutang && !d.settled).toList();
    final done = debts.where((d) => d.settled).toList();
    final totalUtang =
        utangOpen.fold<int>(0, (a, d) => a + d.remaining);
    final totalPiutang =
        piutangOpen.fold<int>(0, (a, d) => a + d.remaining);

    return Scaffold(
      backgroundColor: FtColors.bg,
      floatingActionButton: canTxn
          ? FloatingActionButton.extended(
              onPressed: () => AddDebtSheet.show(context),
              backgroundColor: FtColors.clay,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Catat'),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: FtPageContainer(
          child: FtRefreshable(
            onRefresh: () async {
              ref.invalidate(debtsProvider);
              await ftRefreshDelay();
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                const FtSubHeader(title: 'Utang & Piutang'),
                FtCard(
                  margin: const EdgeInsets.fromLTRB(22, 4, 22, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Eyebrow('Utang kami'),
                            const SizedBox(height: 4),
                            Text(
                              Money.format(totalUtang),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    fontSize: 22,
                                    color: totalUtang > 0
                                        ? FtColors.danger
                                        : FtColors.ink,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Eyebrow('Piutang ke kami'),
                            const SizedBox(height: 4),
                            Text(
                              Money.format(totalPiutang),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    fontSize: 22,
                                    color: FtColors.sage,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                  child: Text(
                    'Catatan saja. Saldo rekening tidak berubah.',
                    style: TextStyle(color: FtColors.ink4, fontSize: 10.5),
                  ),
                ),
                if (debts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.handshake_outlined,
                            size: 48, color: FtColors.ink4),
                        const SizedBox(height: 10),
                        Text(
                          'Belum ada catatan utang atau piutang.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: FtColors.ink3, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                if (utangOpen.isNotEmpty) ...[
                  const SectionLabel('Utang kami'),
                  for (final d in utangOpen)
                    DebtTile(debt: d, canTxn: canTxn),
                ],
                if (piutangOpen.isNotEmpty) ...[
                  const SectionLabel('Piutang ke kami'),
                  for (final d in piutangOpen)
                    DebtTile(debt: d, canTxn: canTxn),
                ],
                if (done.isNotEmpty) ...[
                  const SectionLabel('Selesai'),
                  for (final d in done)
                    DebtTile(debt: d, canTxn: canTxn, dimmed: true),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
