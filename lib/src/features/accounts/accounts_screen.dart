import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_motion.dart';
import '../../ui/ft_ui.dart';
import '../home/widgets/home_formatters.dart';
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

/// Aset screen — mirrors `claude-design/screens-assets.jsx`:
/// hero with 3-segment composition bar + 4 tabs (Tunai / Tabungan / Investasi
/// / Alokasi). Each tab list reuses the `+` from the header.
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this)
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
    final invTotal =
        investments.fold<int>(0, (a, i) => a + i.currentValue);
    final grandTotal = cashTotal + savingsTotal + invTotal;

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.assets,
        child: Column(
          children: [
            FtSubHeader(
              title: 'Aset',
              trailing: _showAddButton()
                  ? FtAddButton(
                      tooltip: _addTooltip(),
                      onTap: () => _onAdd(context, household),
                    )
                  : null,
            ),
            _AssetsHero(
              cash: cashTotal,
              savings: savingsTotal,
              investments: invTotal,
              total: grandTotal,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
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
                  // Default in Material 3 is `label` — that makes the
                  // indicator hug only the text width, which combined with
                  // a 999 radius produced a tall vertical pill. Force the
                  // indicator to fill the whole tab cell.
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicatorPadding: EdgeInsets.zero,
                  indicator: BoxDecoration(
                    color: FtColors.ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  splashBorderRadius: BorderRadius.circular(999),
                  labelColor: FtColors.bg,
                  unselectedLabelColor: FtColors.ink2,
                  labelStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Tunai'),
                    Tab(text: 'Tabungan'),
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
                  _AccountList(
                    household: household,
                    kind: AccountKind.cash,
                    total: cashTotal,
                    accent: FtColors.sky,
                    subtitle: 'Tunai & rekening cair · siap pakai',
                  ),
                  _AccountList(
                    household: household,
                    kind: AccountKind.savings,
                    total: savingsTotal,
                    accent: FtColors.moss,
                    subtitle: 'Dana terkunci untuk tujuan dan dana darurat',
                  ),
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

  bool _showAddButton() => _tabs.index != 3; // Alokasi tab has no "add"
  String _addTooltip() => switch (_tabs.index) {
        0 => 'Tambah rekening tunai',
        1 => 'Tambah tabungan',
        2 => 'Posisi baru',
        _ => '',
      };

  Future<void> _onAdd(BuildContext context, Household household) async {
    final tab = _tabs.index;
    if (tab == 0 || tab == 1) {
      final draft = await showModalBottomSheet<AccountDraft>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AccountEditSheet(
          initialKind: tab == 0 ? AccountKind.cash : AccountKind.savings,
        ),
      );
      if (draft == null) return;
      await ref.read(accountsRepositoryProvider).add(
            householdId: household.id,
            kind: draft.kind,
            label: draft.label,
            hint: draft.hint,
            value: draft.value,
          );
    } else if (tab == 2) {
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

class _AssetsHero extends StatelessWidget {
  const _AssetsHero({
    required this.cash,
    required this.savings,
    required this.investments,
    required this.total,
  });
  final int cash;
  final int savings;
  final int investments;
  final int total;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 4, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Total Aset'),
          const SizedBox(height: 6),
          FtFadeUp(
            duration: const Duration(milliseconds: 380),
            distance: 6,
            child: Text.rich(
              TextSpan(
                text: moneyNoSymbol(total),
                children: [
                  TextSpan(
                    text: ' IDR',
                    style: TextStyle(
                      fontSize: 13,
                      color: FtColors.ink3,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 38,
                    height: 1,
                    letterSpacing: -1.3,
                    fontWeight: FontWeight.w500,
                    color: FtColors.ink,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: FtColors.line, height: 1),
          const SizedBox(height: 14),
          _CompositionBar(
            cash: cash,
            savings: savings,
            investments: investments,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _CompositionStat(
                label: 'Tunai',
                value: cash,
                color: FtColors.sky,
              ),
              _CompositionStat(
                label: 'Tabungan',
                value: savings,
                color: FtColors.moss,
              ),
              _CompositionStat(
                label: 'Investasi',
                value: investments,
                color: FtColors.clay,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompositionBar extends StatelessWidget {
  const _CompositionBar({
    required this.cash,
    required this.savings,
    required this.investments,
  });
  final int cash;
  final int savings;
  final int investments;

  @override
  Widget build(BuildContext context) {
    final total = cash + savings + investments;
    if (total <= 0) {
      return SizedBox(
        height: 8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(color: FtColors.line),
        ),
      );
    }
    int flex(int v) => (v / total * 1000).round().clamp(0, 1000);
    final segments = [
      if (cash > 0)
        Expanded(flex: flex(cash), child: Container(color: FtColors.sky)),
      if (savings > 0)
        Expanded(flex: flex(savings), child: Container(color: FtColors.moss)),
      if (investments > 0)
        Expanded(
            flex: flex(investments), child: Container(color: FtColors.clay)),
    ];
    return SizedBox(
      height: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Row(children: segments),
      ),
    );
  }
}

class _CompositionStat extends StatelessWidget {
  const _CompositionStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: FtColors.ink3,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            compactMoney(value),
            style: TextStyle(
              color: FtColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountList extends ConsumerWidget {
  const _AccountList({
    required this.household,
    required this.kind,
    required this.total,
    required this.accent,
    required this.subtitle,
  });
  final Household household;
  final AccountKind kind;
  final int total;
  final Color accent;
  final String subtitle;

  List<Account> _items() => kind == AccountKind.cash
      ? household.cashAccounts.toList()
      : household.savingsAccounts.toList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = _items()..sort((a, b) => b.value.compareTo(a.value));
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
        child: Center(
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
                    ? 'Belum ada rekening tunai.\nTambah lewat tombol "+".'
                    : 'Belum ada tabungan.\nTambah lewat tombol "+".',
                textAlign: TextAlign.center,
                style: TextStyle(color: FtColors.ink3),
              ),
            ],
          ),
        ),
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
                border:
                    Border.all(color: accent.withValues(alpha: 0.24), width: 0.5),
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
