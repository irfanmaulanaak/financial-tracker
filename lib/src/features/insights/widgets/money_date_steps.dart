import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money_date.dart';
import '../../../core/formatters.dart';
import '../../../core/upcoming.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../categories/budget_move_sheet.dart';
import '../../household/household.dart';
import '../../household/household_providers.dart';
import '../../household/name_format.dart';

class MoneyDateStepScaffold extends StatelessWidget {
  const MoneyDateStepScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FtFadeUp(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
        physics: const BouncingScrollPhysics(),
        children: [
          Eyebrow(eyebrow),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class MoneyDateCelebrateStep extends StatelessWidget {
  const MoneyDateCelebrateStep({
    super.key,
    required this.household,
    required this.savers,
    required this.earned,
    required this.spent,
  });

  final Household household;
  final List<CategoryDelta> savers;
  final int earned;
  final int spent;

  @override
  Widget build(BuildContext context) {
    final net = earned - spent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in savers)
          MoneyDateLineCard(
            color: FtColors.moss,
            icon: Icons.south_rounded,
            title: household.categoryOf(s.id)?.label ?? '-',
            detail:
                'Hemat ${Money.compact(-s.delta)} dibanding siklus lalu.',
            amount: s.spend,
          ),
        if (savers.isEmpty)
          Text(
            'Belum ada pembanding siklus lalu.',
            style: TextStyle(color: FtColors.ink3, fontSize: 13, height: 1.5),
          ),
        const SizedBox(height: 8),
        MoneyDateLineCard(
          color: net >= 0 ? FtColors.sage : FtColors.ochre,
          icon: net >= 0
              ? Icons.account_balance_wallet_rounded
              : Icons.info_outline_rounded,
          title: net >= 0 ? 'Masih sisa' : 'Sementara defisit',
          detail: net >= 0
              ? 'Pemasukan ${Money.compact(earned)} dikurangi pengeluaran ${Money.compact(spent)}'
              : 'Wajar di tanggal tua. Cek langkah berikutnya.',
          amount: net.abs(),
        ),
      ],
    );
  }
}

class MoneyDateRisersStep extends StatelessWidget {
  const MoneyDateRisersStep({
    super.key,
    required this.household,
    required this.risers,
  });

  final Household household;
  final List<CategoryDelta> risers;

  @override
  Widget build(BuildContext context) {
    if (risers.isEmpty) {
      return Text(
        'Pengeluaran stabil dibanding siklus lalu.',
        style: TextStyle(color: FtColors.ink3, fontSize: 13),
      );
    }
    return Column(
      children: [
        for (final r in risers)
          MoneyDateLineCard(
            color: FtColors.ochre,
            icon: Icons.north_rounded,
            title: household.categoryOf(r.id)?.label ?? '-',
            detail: r.baseline > 0
                ? '+${(r.delta * 100 / r.baseline).round()}% vs siklus lalu'
                : 'Baru muncul siklus ini',
            amount: r.spend,
          ),
        const SizedBox(height: 4),
        Text(
          'Bukan untuk menyalahkan. Cukup tahu kenapa, lalu lanjut.',
          style: TextStyle(
              color: FtColors.ink4, fontSize: 11, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class MoneyDateUpcomingStep extends StatelessWidget {
  const MoneyDateUpcomingStep({super.key, required this.items});

  final List<UpcomingItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'Tidak ada jatuh tempo kartu atau tagihan rutin sampai minggu depan.',
        style: TextStyle(color: FtColors.ink3, fontSize: 13, height: 1.5),
      );
    }
    return Column(
      children: [
        for (final i in items)
          MoneyDateLineCard(
            color: FtColors.ochre,
            icon: i.kind == UpcomingKind.cardDue
                ? Icons.credit_card_rounded
                : Icons.receipt_long_rounded,
            title: i.title,
            detail: i.kind == UpcomingKind.cardDue
                ? 'Jatuh tempo ${Dates.dayMonth(i.date)}'
                : 'Biasanya tanggal ${i.date.day} (±)',
            amount: i.amount,
          ),
      ],
    );
  }
}

class MoneyDateDecisionStep extends ConsumerWidget {
  const MoneyDateDecisionStep({
    super.key,
    required this.household,
    required this.moves,
    required this.overCategoryId,
  });

  final Household household;
  final List<BudgetMove> moves;
  final String? overCategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canFull = ref.watch(canWriteAllProvider);
    final overCat =
        overCategoryId != null ? household.categoryOf(overCategoryId!) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (moves.isNotEmpty) ...[
          const Eyebrow('Pergeseran anggaran siklus ini'),
          const SizedBox(height: 8),
          for (final m in moves)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${prettyName(household.memberOf(m.by)?.displayName ?? 'Anggota')} '
                'menggeser ${Money.compact(m.amount)} dari '
                '${household.categoryOf(m.fromId)?.label ?? '-'} ke '
                '${household.categoryOf(m.toId)?.label ?? '-'} '
                '(${Dates.dayMonth(m.at)})',
                style: TextStyle(
                    color: FtColors.ink2, fontSize: 12, height: 1.4),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (overCat != null && canFull) ...[
          Text(
            '"${overCat.label}" paling melebihi anggaran. Mau geser sedikit dari kategori yang longgar?',
            style: TextStyle(color: FtColors.ink, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                BudgetMoveSheet.show(context, toId: overCat.id),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Geser anggaran'),
          ),
        ] else
          Text(
            'Anggaran aman. Boleh tutup money date atau sepakati satu hal kecil untuk siklus depan.',
            style: TextStyle(color: FtColors.ink2, fontSize: 13, height: 1.5),
          ),
      ],
    );
  }
}

class MoneyDateLineCard extends StatelessWidget {
  const MoneyDateLineCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.detail,
    required this.amount,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String detail;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: color.withValues(alpha: 0.24), width: 0.5),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            Money.format(amount),
            style: TextStyle(
              color: FtColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
