import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../expenses/expense.dart';
import '../expenses/expense_detail_sheet.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import '../incomes/income.dart';
import '../transfers/transfer.dart';
import 'account.dart';
import 'account_history_providers.dart';

/// Transaction history for a single cash/savings account. Lists money out
/// (expenses) and money in (incomes) merged by date desc.
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final account = household.accountOf(accountId);
    if (account == null) return const _NotFoundView();

    final expensesAsync = ref.watch(
      accountExpensesProvider((hid: household.id, accountId: accountId)),
    );
    final incomesAsync = ref.watch(
      accountIncomesProvider((hid: household.id, accountId: accountId)),
    );
    final outgoingAsync = ref.watch(
      accountOutgoingTransfersProvider(
          (hid: household.id, accountId: accountId)),
    );
    final incomingAsync = ref.watch(
      accountIncomingTransfersProvider(
          (hid: household.id, accountId: accountId)),
    );

    final expenses = expensesAsync.value ?? const <Expense>[];
    final incomes = incomesAsync.value ?? const <Income>[];
    final outgoing = outgoingAsync.value ?? const <Transfer>[];
    final incoming = incomingAsync.value ?? const <Transfer>[];
    final entries = <_TxnEntry>[
      for (final e in expenses) _TxnEntry.expense(e),
      for (final i in incomes) _TxnEntry.income(i),
      for (final t in outgoing) _TxnEntry.transferOut(t),
      for (final t in incoming) _TxnEntry.transferIn(t),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        bottom: false,
        child: FtRefreshable(
          onRefresh: () async {
            ref.invalidate(currentHouseholdProvider);
            ref.invalidate(accountExpensesProvider(
                (hid: household.id, accountId: accountId)));
            ref.invalidate(accountIncomesProvider(
                (hid: household.id, accountId: accountId)));
            ref.invalidate(accountOutgoingTransfersProvider(
                (hid: household.id, accountId: accountId)));
            ref.invalidate(accountIncomingTransfersProvider(
                (hid: household.id, accountId: accountId)));
            await ftRefreshDelay();
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              FtSubHeader(title: account.label),
              _SummaryCard(account: account),
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 14, 22, 8),
                child: Eyebrow('Transaksi'),
              ),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      'Belum ada transaksi pada rekening ini.',
                      style: TextStyle(color: FtColors.ink3),
                    ),
                  ),
                )
              else
                for (final entry in entries)
                  _TxnTile(
                    entry: entry,
                    household: household,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final kindLabel = account.kind == AccountKind.cash
        ? accountSubKindLabel(account.subKind)
        : 'Tabungan';
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(kindLabel),
          const SizedBox(height: 6),
          Text(
            Money.format(account.value),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          if (account.hint != null && account.hint!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              account.hint!,
              style: TextStyle(color: FtColors.ink3, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const FtSubHeader(title: 'Rekening'),
            Expanded(
              child: Center(
                child: Text(
                  'Rekening tidak ditemukan.',
                  style: TextStyle(color: FtColors.ink3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TxnEntry {
  _TxnEntry.expense(Expense e)
      : expense = e,
        income = null,
        transfer = null,
        transferOutgoing = false,
        date = e.date;
  _TxnEntry.income(Income i)
      : expense = null,
        income = i,
        transfer = null,
        transferOutgoing = false,
        date = i.date;
  _TxnEntry.transferOut(Transfer t)
      : expense = null,
        income = null,
        transfer = t,
        transferOutgoing = true,
        date = t.date;
  _TxnEntry.transferIn(Transfer t)
      : expense = null,
        income = null,
        transfer = t,
        transferOutgoing = false,
        date = t.date;
  final Expense? expense;
  final Income? income;
  final Transfer? transfer;
  final bool transferOutgoing;
  final DateTime date;

  bool get isExpense => expense != null;
  bool get isTransfer => transfer != null;
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({required this.entry, required this.household});
  final _TxnEntry entry;
  final Household household;

  @override
  Widget build(BuildContext context) {
    if (entry.isTransfer) {
      final t = entry.transfer!;
      final outgoing = entry.transferOutgoing;
      final counterpartyId =
          outgoing ? t.destinationAccountId : t.sourceAccountId;
      final counterparty = household.accountOf(counterpartyId);
      final actor = household.memberOf(t.transferredBy);
      // Outgoing nets total = amount + fee; incoming only amount lands.
      final signedAmount = outgoing ? -(t.amount + t.fee) : t.amount;
      final color = outgoing ? FtColors.ink2 : FtColors.moss;
      final feeNote =
          outgoing && t.fee > 0 ? 'Biaya ${Money.format(t.fee)}' : null;
      return FtCard(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _IconBadge(
              color: color,
              icon: outgoing
                  ? Icons.north_east_rounded
                  : Icons.south_west_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outgoing
                        ? 'Pindah ke ${counterparty?.label ?? '-'}'
                        : 'Pindah dari ${counterparty?.label ?? '-'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      Dates.short(t.date),
                      if (actor != null) prettyName(actor.displayName),
                      ?feeNote,
                      if (t.note != null && t.note!.isNotEmpty) t.note!,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: FtColors.ink3, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${signedAmount < 0 ? '−' : '+'}${Money.format(signedAmount.abs())}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
    if (entry.isExpense) {
      final e = entry.expense!;
      final cat = household.categoryOf(e.categoryId);
      final spender = household.memberOf(e.spentBy);
      return FtCard(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        onTap: () => ExpenseDetailSheet.show(context: context, expense: e),
        child: Row(
          children: [
            _IconBadge(
              color: cat != null ? parseColor(cat.color) : FtColors.ink3,
              icon: Icons.remove_rounded,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat?.label ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      Dates.short(e.date),
                      if (spender != null) prettyName(spender.displayName),
                      if (e.note != null && e.note!.isNotEmpty) e.note!,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: FtColors.ink3, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '−${Money.format(e.amount)}',
              style: TextStyle(
                color: FtColors.danger,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final i = entry.income!;
    final receiver = household.memberOf(i.receivedBy);
    return FtCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _IconBadge(color: FtColors.sage, icon: Icons.add_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incomeSourceLabel(i.source),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    Dates.short(i.date),
                    if (receiver != null) prettyName(receiver.displayName),
                    if (i.note != null && i.note!.isNotEmpty) i.note!,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '+${Money.format(i.amount)}',
            style: TextStyle(
              color: FtColors.sage,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 0.5),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}
