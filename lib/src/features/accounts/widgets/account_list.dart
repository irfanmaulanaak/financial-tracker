import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../core/hide_assets_provider.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../account.dart';
import '../accounts_repository.dart';
import 'account_edit_sheet.dart';

class AccountList extends ConsumerWidget {
  const AccountList({
    super.key,
    required this.accounts,
    required this.kind,
    required this.householdId,
  });
  final List<Account> accounts;
  final AccountKind kind;
  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideAssetsProvider);
    if (accounts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Belum ada akun.\nTambah lewat tombol "+".',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }
    final sorted = [...accounts]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: sorted.length,
      itemBuilder: (_, i) {
        final a = sorted[i];
        final color = kind == AccountKind.cash ? FtColors.sky : FtColors.moss;
        return FtCard(
          margin: EdgeInsets.fromLTRB(22, i == 0 ? 8 : 0, 22, 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: () => _openEditSheet(context, ref, a),
          onLongPress: () => _confirmDelete(context, ref, a),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  kind == AccountKind.cash
                      ? Icons.account_balance_wallet_outlined
                      : Icons.savings_outlined,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.label,
                      style: TextStyle(
                        color: FtColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (a.hint != null)
                      Text(
                        a.hint!,
                        style: TextStyle(
                          color: FtColors.ink3,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                hidden ? maskMoney() : Money.format(a.value),
                style: TextStyle(
                  color: FtColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditSheet(
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
    try {
      if (result.deltaMode) {
        await ref
            .read(accountsRepositoryProvider)
            .applyDelta(
              householdId: householdId,
              kind: a.kind,
              accountId: a.id,
              delta: result.value,
            );
      } else {
        await ref
            .read(accountsRepositoryProvider)
            .updateAccount(
              householdId: householdId,
              kind: a.kind,
              accountId: a.id,
              label: result.label,
              hint: result.hint,
              value: result.value,
              subKind: result.kind == AccountKind.cash ? result.subKind : null,
              newKind: result.kind != a.kind ? result.kind : null,
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
      await ref
          .read(accountsRepositoryProvider)
          .delete(householdId: householdId, kind: a.kind, accountId: a.id);
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menghapus rekening');
      }
    }
  }
}
