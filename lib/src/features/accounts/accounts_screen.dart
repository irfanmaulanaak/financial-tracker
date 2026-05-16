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
import 'widgets/alokasi_tab.dart';
import 'widgets/investasi_list.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this)
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
                tooltip: switch (_tabs.index) {
                  0 => 'Tambah rekening',
                  1 => 'Posisi baru',
                  _ => '',
                },
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
                  indicator: BoxDecoration(
                    color: FtColors.ink,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  labelColor: FtColors.bg,
                  unselectedLabelColor: FtColors.ink2,
                  tabs: const [
                    Tab(text: 'Rekening'),
                    Tab(text: 'Investasi'),
                    Tab(text: 'Alokasi'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _RekeningList(household: household),
                  InvestasiList(
                    householdId: household.id,
                    items: investments,
                    isLoading: investmentsAsync.isLoading,
                    error: investmentsAsync.error,
                  ),
                  AlokasiTab(
                    household: household,
                    investments: investments,
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
      final draft = await showModalBottomSheet<InvestmentDraft>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const InvestmentEditSheet(),
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
      return Center(
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
                            style: TextStyle(
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
                Money.format(a.value),
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


