import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import 'account.dart';
import 'accounts_repository.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cashTotal = household.cashAccounts.fold<int>(
      0,
      (a, b) => a + b.value,
    );
    final savingsTotal = household.savingsAccounts.fold<int>(
      0,
      (a, b) => a + b.value,
    );
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: FtColors.bg,
        body: FtAppChrome(
          current: FtTab.assets,
          child: Column(
            children: [
              FtSubHeader(
                title: 'Aset',
                trailing: IconButton.filled(
                  onPressed: () => _openAddSheet(context, ref, household),
                  icon: const Icon(Icons.add),
                ),
              ),
              FtCard(
                margin: const EdgeInsets.fromLTRB(22, 4, 22, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Total Aset Cair'),
                    const SizedBox(height: 6),
                    Text(
                      Money.format(cashTotal + savingsTotal),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 14),
                    FtProgressBar(
                      value: cashTotal,
                      max: cashTotal + savingsTotal == 0
                          ? 1
                          : cashTotal + savingsTotal,
                      color: FtColors.sky,
                      trackColor: FtColors.moss.withValues(alpha: 0.22),
                      height: 7,
                    ),
                    const SizedBox(height: 14),
                    FtStatGrid(
                      items: [
                        FtStatItem(
                          label: 'Tunai / Debit',
                          value: Money.format(cashTotal),
                          color: FtColors.sky,
                        ),
                        FtStatItem(
                          label: 'Tabungan',
                          value: Money.format(savingsTotal),
                          color: FtColors.moss,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: FtColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: FtColors.line, width: 0.5),
                  ),
                  child: const TabBar(
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: FtColors.ink,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    labelColor: FtColors.bg,
                    unselectedLabelColor: FtColors.ink2,
                    tabs: [
                      Tab(text: 'Tunai / Debit'),
                      Tab(text: 'Tabungan'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _AccountList(
                      accounts: household.cashAccounts,
                      kind: AccountKind.cash,
                      householdId: household.id,
                    ),
                    _AccountList(
                      accounts: household.savingsAccounts,
                      kind: AccountKind.savings,
                      householdId: household.id,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddSheet(
    BuildContext context,
    WidgetRef ref,
    Household household,
  ) async {
    final result = await showModalBottomSheet<_AccountDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AccountEditSheet(),
    );
    if (result == null) return;
    await ref
        .read(accountsRepositoryProvider)
        .add(
          householdId: household.id,
          kind: result.kind,
          label: result.label,
          hint: result.hint,
          value: result.value,
        );
  }
}

class _AccountList extends ConsumerWidget {
  const _AccountList({
    required this.accounts,
    required this.kind,
    required this.householdId,
  });
  final List<Account> accounts;
  final AccountKind kind;
  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      style: const TextStyle(
                        color: FtColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (a.hint != null)
                      Text(
                        a.hint!,
                        style: const TextStyle(
                          color: FtColors.ink3,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                Money.format(a.value),
                style: const TextStyle(
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
    final result = await showModalBottomSheet<_AccountDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AccountEditSheet(initial: a),
    );
    if (result == null) return;
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
    await ref
        .read(accountsRepositoryProvider)
        .delete(householdId: householdId, kind: a.kind, accountId: a.id);
  }
}

class _AccountDraft {
  final AccountKind kind;
  final String label;
  final String? hint;
  final int value;
  final bool deltaMode;
  const _AccountDraft({
    required this.kind,
    required this.label,
    required this.hint,
    required this.value,
    this.deltaMode = false,
  });
}

class _AccountEditSheet extends StatefulWidget {
  const _AccountEditSheet({this.initial});
  final Account? initial;

  @override
  State<_AccountEditSheet> createState() => _AccountEditSheetState();
}

class _AccountEditSheetState extends State<_AccountEditSheet> {
  late final _label = TextEditingController(text: widget.initial?.label ?? '');
  late final _hint = TextEditingController(text: widget.initial?.hint ?? '');
  late final _value = TextEditingController(
    text: widget.initial != null ? widget.initial!.value.toString() : '',
  );
  late final _delta = TextEditingController();
  AccountKind _kind = AccountKind.cash;
  bool _deltaMode = false;

  @override
  void initState() {
    super.initState();
    _kind = widget.initial?.kind ?? AccountKind.cash;
  }

  @override
  void dispose() {
    _label.dispose();
    _hint.dispose();
    _value.dispose();
    _delta.dispose();
    super.dispose();
  }

  void _save() {
    final label = _label.text.trim();
    if (label.isEmpty && widget.initial == null) return;
    final hint = _hint.text.trim().isEmpty ? null : _hint.text.trim();

    if (_deltaMode) {
      final raw = _delta.text.trim();
      if (raw.isEmpty) return;
      final delta = int.tryParse(raw);
      if (delta == null) return;
      Navigator.pop(
        context,
        _AccountDraft(
          kind: _kind,
          label: label,
          hint: hint,
          value: delta,
          deltaMode: true,
        ),
      );
    } else {
      final value =
          int.tryParse(_value.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
      Navigator.pop(
        context,
        _AccountDraft(kind: _kind, label: label, hint: hint, value: value),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit akun' : 'Akun baru',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (!isEdit) ...[
              SegmentedButton<AccountKind>(
                segments: const [
                  ButtonSegment(
                    value: AccountKind.cash,
                    label: Text('Tunai/Debit'),
                  ),
                  ButtonSegment(
                    value: AccountKind.savings,
                    label: Text('Tabungan'),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama akun'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hint,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'mis. BCA 1234',
              ),
            ),
            const SizedBox(height: 16),
            if (isEdit)
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Set saldo')),
                  ButtonSegment(value: true, label: Text('Tambah / kurang')),
                ],
                selected: {_deltaMode},
                onSelectionChanged: (s) => setState(() => _deltaMode = s.first),
              ),
            const SizedBox(height: 12),
            if (_deltaMode)
              TextField(
                controller: _delta,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'-?\d*')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Delta',
                  prefixText: 'Rp ',
                  helperText: 'gunakan tanda minus untuk kurang',
                ),
              )
            else
              TextField(
                controller: _value,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Saldo',
                  prefixText: 'Rp ',
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}
