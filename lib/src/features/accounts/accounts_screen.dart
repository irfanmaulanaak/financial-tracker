import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_ui.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../investments/investment.dart';
import '../investments/investments_repository.dart';
import '../investments/investments_screen.dart' show investmentsProvider;
import 'account.dart';
import 'accounts_repository.dart';
import 'widgets/account_edit_sheet.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (mounted) setState(() {});
    });

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final investmentsAsync = ref.watch(investmentsProvider(household.id));
    final investments = investmentsAsync.value ?? const <Investment>[];

    final cashTotal =
        household.cashAccounts.fold<int>(0, (a, b) => a + b.value);
    final savingsTotal =
        household.savingsAccounts.fold<int>(0, (a, b) => a + b.value);
    final rekTotal = cashTotal + savingsTotal;
    final invTotal =
        investments.fold<int>(0, (a, i) => a + i.currentValue);
    final grandTotal = rekTotal + invTotal;

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.assets,
        child: Column(
          children: [
            FtSubHeader(
              title: 'Aset',
              trailing: FtAddButton(
                tooltip: _tabs.index == 0 ? 'Tambah rekening' : 'Posisi baru',
                onTap: () => _onAdd(context, household),
              ),
            ),
            FtCard(
              margin: const EdgeInsets.fromLTRB(22, 4, 22, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Total Aset'),
                  const SizedBox(height: 6),
                  Text(
                    Money.format(grandTotal),
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 14),
                  FtProgressBar(
                    value: rekTotal,
                    max: grandTotal == 0 ? 1 : grandTotal,
                    color: FtColors.sky,
                    trackColor: FtColors.clay.withValues(alpha: 0.22),
                    height: 7,
                  ),
                  const SizedBox(height: 14),
                  FtStatGrid(
                    items: [
                      FtStatItem(
                        label: 'Rekening',
                        value: Money.format(rekTotal),
                        color: FtColors.sky,
                      ),
                      FtStatItem(
                        label: 'Investasi',
                        value: Money.format(invTotal),
                        color: FtColors.clay,
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
                child: TabBar(
                  controller: _tabs,
                  onTap: (_) {
                    FtHaptics.select();
                    setState(() {});
                  },
                  dividerColor: Colors.transparent,
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  indicator: const BoxDecoration(
                    color: FtColors.ink,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  labelColor: FtColors.bg,
                  unselectedLabelColor: FtColors.ink2,
                  tabs: const [
                    Tab(text: 'Rekening'),
                    Tab(text: 'Investasi'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _RekeningList(household: household),
                  _InvestasiList(
                    householdId: household.id,
                    items: investments,
                    isLoading: investmentsAsync.isLoading,
                    error: investmentsAsync.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAdd(BuildContext context, Household household) async {
    if (_tabs.index == 0) {
      final result = await showModalBottomSheet<AccountDraft>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const AccountEditSheet(),
      );
      if (result == null) return;
      await ref.read(accountsRepositoryProvider).add(
            householdId: household.id,
            kind: result.kind,
            label: result.label,
            hint: result.hint,
            value: result.value,
          );
    } else {
      final draft = await showModalBottomSheet<_InvestmentDraft>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _InvestmentEditSheet(),
      );
      if (draft == null) return;
      await ref.read(investmentsRepositoryProvider).add(
            hid: household.id,
            label: draft.label,
            type: draft.type,
            currentValue: draft.currentValue,
            costBasis: draft.costBasis,
          );
    }
  }
}

class _RekeningList extends ConsumerWidget {
  const _RekeningList({required this.household});
  final Household household;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = <Account>[
      ...household.cashAccounts,
      ...household.savingsAccounts,
    ]..sort((a, b) => b.value.compareTo(a.value));

    if (all.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Belum ada rekening.\nTambah lewat tombol "+".',
            textAlign: TextAlign.center,
            style: TextStyle(color: FtColors.ink3),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 120),
      itemCount: all.length,
      itemBuilder: (_, i) {
        final a = all[i];
        final isCash = a.kind == AccountKind.cash;
        final color = isCash ? FtColors.sky : FtColors.moss;
        return FtCard(
          margin: EdgeInsets.fromLTRB(22, i == 0 ? 4 : 0, 22, 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          onTap: () => _openEdit(context, ref, a),
          onLongPress: () => _confirmDelete(context, ref, a),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: color.withValues(alpha: 0.24), width: 0.5),
                ),
                child: Icon(
                  isCash
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            a.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FtColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _KindChip(isCash: isCash),
                      ],
                    ),
                    if (a.hint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        a.hint!,
                        style: const TextStyle(
                          color: FtColors.ink3,
                          fontSize: 11,
                        ),
                      ),
                    ],
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

class _KindChip extends StatelessWidget {
  const _KindChip({required this.isCash});
  final bool isCash;

  @override
  Widget build(BuildContext context) {
    final color = isCash ? FtColors.sky : FtColors.moss;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        isCash ? 'Tunai' : 'Tabungan',
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _InvestasiList extends ConsumerWidget {
  const _InvestasiList({
    required this.householdId,
    required this.items,
    required this.isLoading,
    required this.error,
  });
  final String householdId;
  final List<Investment> items;
  final bool isLoading;
  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text('Gagal: $error'));
    }
    final summary = summarisePortfolio(items);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 120),
      children: [
        _InvestasiSummary(summary: summary),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'Belum ada investasi.\nTambah posisi via tombol "+".',
                textAlign: TextAlign.center,
                style: TextStyle(color: FtColors.ink3),
              ),
            ),
          )
        else
          for (final i in items)
            _InvestmentTile(
              inv: i,
              onUpdate: () => _openUpdate(context, ref, i),
              onDelete: () => _confirmDelete(context, ref, i),
            ),
      ],
    );
  }

  Future<void> _openUpdate(
      BuildContext context, WidgetRef ref, Investment i) async {
    final ctrl = TextEditingController(text: i.currentValue.toString());
    final v = await showModalBottomSheet<int>(
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
            Text('Update ${i.label}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nilai sekarang',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(ctrl.text);
                if (v == null) return;
                Navigator.pop(context, v);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (v != null) {
      await ref
          .read(investmentsRepositoryProvider)
          .updateValue(hid: householdId, id: i.id, currentValue: v);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Investment i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus "${i.label}"?'),
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
      await ref
          .read(investmentsRepositoryProvider)
          .delete(hid: householdId, id: i.id);
    }
  }
}

class _InvestasiSummary extends StatelessWidget {
  const _InvestasiSummary({required this.summary});
  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context) {
    final positive = summary.totalGain >= 0;
    final color = positive ? FtColors.sage : FtColors.danger;
    return FtCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Total portofolio'),
          const SizedBox(height: 6),
          Text(
            Money.format(summary.totalValue),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                positive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '${positive ? '+' : ''}${Money.format(summary.totalGain)} (${(summary.gainPct * 100).toStringAsFixed(1)}%)',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Text(
                '${summary.distinctTypes} jenis aset',
                style: const TextStyle(color: FtColors.ink3, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvestmentTile extends StatelessWidget {
  const _InvestmentTile({
    required this.inv,
    required this.onUpdate,
    required this.onDelete,
  });
  final Investment inv;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final positive = inv.gain >= 0;
    final color = positive ? FtColors.sage : FtColors.danger;
    return FtCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onUpdate,
      onLongPress: onDelete,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FtColors.clay.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: FtColors.clay.withValues(alpha: 0.24), width: 0.5),
            ),
            child: const Icon(Icons.trending_up, color: FtColors.clay),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${investmentTypeLabel(inv.type)} • cost ${Money.format(inv.costBasis)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: FtColors.ink3, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money.format(inv.currentValue),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${positive ? '+' : ''}${(inv.gainPct * 100).toStringAsFixed(1)}%',
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvestmentDraft {
  final String label;
  final InvestmentType type;
  final int currentValue;
  final int costBasis;
  const _InvestmentDraft(this.label, this.type, this.currentValue, this.costBasis);
}

class _InvestmentEditSheet extends StatefulWidget {
  const _InvestmentEditSheet();
  @override
  State<_InvestmentEditSheet> createState() => _InvestmentEditSheetState();
}

class _InvestmentEditSheetState extends State<_InvestmentEditSheet> {
  final _label = TextEditingController();
  final _current = TextEditingController();
  final _cost = TextEditingController();
  InvestmentType _type = InvestmentType.reksadana;

  @override
  void dispose() {
    _label.dispose();
    _current.dispose();
    _cost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Investasi baru',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'mis. BBCA / Sucorinvest Sharia',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InvestmentType>(
              initialValue: _type,
              items: [
                for (final t in InvestmentType.values)
                  DropdownMenuItem(
                    value: t,
                    child: Text(investmentTypeLabel(t)),
                  ),
              ],
              onChanged: (v) =>
                  setState(() => _type = v ?? InvestmentType.reksadana),
              decoration: const InputDecoration(labelText: 'Jenis'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cost,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Modal (cost basis)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _current,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nilai saat ini',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final label = _label.text.trim();
                final cv = int.tryParse(_current.text) ?? 0;
                final cb = int.tryParse(_cost.text) ?? 0;
                if (label.isEmpty || cv < 0 || cb < 0) return;
                Navigator.pop(
                    context, _InvestmentDraft(label, _type, cv, cb));
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
