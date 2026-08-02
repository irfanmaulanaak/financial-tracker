import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters.dart';
import '../../../core/hide_assets_provider.dart';
import '../../../theme.dart';
import '../../../ui/ft_refresh.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household_providers.dart' show currentHouseholdProvider;
import '../../home/widgets/home_formatters.dart';
import '../../household/household.dart';
import '../account.dart';
import '../accounts_repository.dart';
import 'account_edit_sheet.dart';

/// Filter for the Tunai (cash) tab. Tabungan ignores this.
enum CashFilter { all, bank, ewallet }

/// Tab body shared by `Tunai` and `Tabungan`. Renders an empty-state
/// placeholder + dashed-add button when the account list is empty,
/// otherwise a labeled count row → grouped card with each account row →
/// dashed-add button. Long-press a row to delete.
class AccountTab extends ConsumerStatefulWidget {
  const AccountTab({
    super.key,
    required this.household,
    required this.kind,
    required this.total,
    required this.accent,
    required this.subtitle,
    required this.onAdd,
  });

  final Household household;
  final AccountKind kind;
  final int total;
  final Color accent;
  final String subtitle;
  final VoidCallback onAdd;

  @override
  ConsumerState<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends ConsumerState<AccountTab> {
  CashFilter _filter = CashFilter.all;

  List<Account> _items() {
    final base = widget.kind == AccountKind.cash
        ? widget.household.cashAccounts.toList()
        : widget.household.savingsAccounts.toList();
    if (widget.kind != AccountKind.cash) return base;
    return switch (_filter) {
      CashFilter.all => base,
      CashFilter.bank =>
        base.where((a) => a.subKind == AccountSubKind.bank).toList(),
      CashFilter.ewallet =>
        base.where((a) => a.subKind == AccountSubKind.ewallet).toList(),
    };
  }

  String get _addLabel => widget.kind == AccountKind.cash
      ? 'Tambah rekening tunai'
      : 'Tambah tabungan';

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SegmentedButton<CashFilter>(
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ),
        segments: const [
          ButtonSegment(value: CashFilter.all, label: Text('Semua')),
          ButtonSegment(value: CashFilter.bank, label: Text('Bank')),
          ButtonSegment(value: CashFilter.ewallet, label: Text('E-wallet')),
        ],
        selected: {_filter},
        onSelectionChanged: (s) => setState(() => _filter = s.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hidden = ref.watch(hideAssetsProvider);
    final hasAny = (widget.kind == AccountKind.cash
            ? widget.household.cashAccounts
            : widget.household.savingsAccounts)
        .isNotEmpty;
    final items = _items()..sort((a, b) => b.value.compareTo(a.value));
    if (!hasAny) {
      return FtRefreshable(
        onRefresh: () async {
          ref.invalidate(currentHouseholdProvider);
          await ftRefreshDelay();
        },
        child: ListView(
        padding:
            const EdgeInsets.fromLTRB(22, 28, 22, kFtFabClearance),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.kind == AccountKind.cash
                      ? Icons.account_balance_wallet_outlined
                      : Icons.savings_outlined,
                  size: 40,
                  color: FtColors.ink4,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.kind == AccountKind.cash
                      ? 'Belum ada rekening tunai.'
                      : 'Belum ada tabungan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FtColors.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FtDashedAdd(label: _addLabel, onTap: widget.onAdd),
        ],
        ),
      );
    }
    return FtRefreshable(
      onRefresh: () async {
        ref.invalidate(currentHouseholdProvider);
        await ftRefreshDelay();
      },
      child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, kFtFabClearance),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Eyebrow('${items.length} rekening'),
            Text(
              hidden ? maskMoney() : compactMoney(widget.total),
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.subtitle,
          style: TextStyle(
            color: FtColors.ink3,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        if (widget.kind == AccountKind.cash) _filterBar(),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Tidak ada rekening di filter ini.',
                style: TextStyle(color: FtColors.ink3, fontSize: 12),
              ),
            ),
          )
        else
          FtCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(),
                  _AccountRow(
                    account: items[i],
                    accent: widget.accent,
                    hidden: hidden,
                    onTap: () => context.push('/accounts/${items[i].id}'),
                    onLongPress: () => _openEdit(context, ref, items[i]),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        FtDashedAdd(label: _addLabel, onTap: widget.onAdd),
      ],
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    Account a,
  ) async {
    final result = await showModalBottomSheet<AccountDraft>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => AccountEditSheet(
        initial: a,
        onDelete: () => _confirmDelete(context, ref, a),
      ),
    );
    if (result == null) return;
    try {
      if (result.deltaMode) {
        await ref.read(accountsRepositoryProvider).applyDelta(
              householdId: widget.household.id,
              kind: a.kind,
              accountId: a.id,
              delta: result.value,
            );
      } else {
        await ref.read(accountsRepositoryProvider).updateAccount(
              householdId: widget.household.id,
              kind: a.kind,
              accountId: a.id,
              label: result.label,
              hint: result.hint,
              value: result.value,
              subKind: result.kind == AccountKind.cash ? result.subKind : null,
              newKind: result.kind != a.kind ? result.kind : null,
              liquid: result.kind == AccountKind.savings ? result.liquid : null,
            );
      }
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menyimpan rekening');
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Account a,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus "${a.label}"?'),
        content: const Text('Saldo dan riwayat akan hilang dari ringkasan.'),
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
    if (ok != true) return;
    try {
      await ref.read(accountsRepositoryProvider).delete(
            householdId: widget.household.id,
            kind: a.kind,
            accountId: a.id,
          );
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menghapus rekening');
      }
    }
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
    this.hidden = false,
  });
  final Account account;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final iconData = account.kind == AccountKind.cash &&
            account.subKind == AccountSubKind.ewallet
        ? Icons.account_balance_wallet_rounded
        : Icons.account_balance_rounded;
    return FtTapScale(
      scale: 0.98,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: accent.withValues(alpha: 0.24), width: 0.5),
              ),
              child: Icon(
                iconData,
                size: 16,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (account.hint != null && account.hint!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      account.hint!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: FtColors.ink3,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              hidden ? maskMoney() : Money.format(account.value),
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 16, color: FtColors.ink4),
          ],
        ),
      ),
    );
  }
}
