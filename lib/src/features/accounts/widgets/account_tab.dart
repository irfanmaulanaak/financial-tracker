import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../../household/household.dart';
import '../account.dart';
import '../accounts_repository.dart';
import 'account_edit_sheet.dart';

/// Tab body shared by `Tunai` and `Tabungan`. Renders an empty-state
/// placeholder + dashed-add button when the account list is empty,
/// otherwise a labeled count row → grouped card with each account row →
/// dashed-add button. Long-press a row to delete.
class AccountTab extends ConsumerWidget {
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

  List<Account> _items() => kind == AccountKind.cash
      ? household.cashAccounts.toList()
      : household.savingsAccounts.toList();

  String get _addLabel => kind == AccountKind.cash
      ? 'Tambah rekening tunai'
      : 'Tambah tabungan';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _items()..sort((a, b) => b.value.compareTo(a.value));
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 120),
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  kind == AccountKind.cash
                      ? Icons.account_balance_wallet_outlined
                      : Icons.savings_outlined,
                  size: 40,
                  color: FtColors.ink4,
                ),
                const SizedBox(height: 8),
                Text(
                  kind == AccountKind.cash
                      ? 'Belum ada rekening tunai.'
                      : 'Belum ada tabungan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: FtColors.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FtDashedAdd(label: _addLabel, onTap: onAdd),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 120),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Eyebrow('${items.length} rekening'),
            Text(
              compactMoney(total),
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
          subtitle,
          style: TextStyle(
            color: FtColors.ink3,
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        FtCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(),
                _AccountRow(
                  account: items[i],
                  accent: accent,
                  onTap: () => _openEdit(context, ref, items[i]),
                  onLongPress: () => _confirmDelete(context, ref, items[i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        FtDashedAdd(label: _addLabel, onTap: onAdd),
      ],
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
      builder: (_) => AccountEditSheet(initial: a),
    );
    if (result == null) return;
    if (result.deltaMode) {
      await ref.read(accountsRepositoryProvider).applyDelta(
            householdId: household.id,
            kind: a.kind,
            accountId: a.id,
            delta: result.value,
          );
    } else {
      await ref.read(accountsRepositoryProvider).updateAccount(
            householdId: household.id,
            kind: a.kind,
            accountId: a.id,
            label: result.label,
            hint: result.hint,
            value: result.value,
          );
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
    await ref.read(accountsRepositoryProvider).delete(
          householdId: household.id,
          kind: a.kind,
          accountId: a.id,
        );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
  });
  final Account account;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
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
                Icons.account_balance_rounded,
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
              Money.format(account.value),
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
