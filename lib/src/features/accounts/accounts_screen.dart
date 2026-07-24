import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_ui.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../investments/investment.dart';
import '../investments/investments_repository.dart';
import 'account.dart';
import 'accounts_repository.dart';
import 'widgets/account_edit_sheet.dart';
import 'widgets/alokasi_tab.dart';
import 'widgets/assets_hero.dart';
import 'widgets/cash_tab.dart';
import 'widgets/investasi_list.dart';
import 'widgets/savings_tab.dart';

/// Aset screen — hero with 3-segment composition bar + 4 tabs
/// (Tunai / Tabungan / Investasi / Alokasi). Each tab list reuses the `+`
/// from the header.
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
      return Scaffold(
        backgroundColor: FtColors.bg,
        body: const FtSkeletonListView(count: 4, tileHeight: 84),
      );
    }
    final investmentsAsync = ref.watch(investmentsProvider(household.id));
    final investments = investmentsAsync.value ?? const <Investment>[];

    final cashTotal =
        household.cashAccounts.fold<int>(0, (a, b) => a + b.value);
    final savingsTotal =
        household.savingsAccounts.fold<int>(0, (a, b) => a + b.value);
    final invTotal = investments.fold<int>(0, (a, i) => a + i.currentValue);
    final grandTotal = cashTotal + savingsTotal + invTotal;

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.assets,
        child: Column(
          children: [
            const FtSubHeader(title: 'Aset'),
            AssetsHero(
              cash: cashTotal,
              savings: savingsTotal,
              investments: invTotal,
              total: grandTotal,
            ),
            if (ref.watch(canRecordTxnProvider) &&
                household.cashAccounts.length +
                        household.savingsAccounts.length >=
                    2) ...[
              const SizedBox(height: 4),
              const _TransferCta(),
            ],
            _TabsBar(controller: _tabs),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  CashTab(
                    household: household,
                    total: cashTotal,
                    onAdd: () =>
                        _addAccount(context, household, AccountKind.cash),
                  ),
                  SavingsTab(
                    household: household,
                    total: savingsTotal,
                    onAdd: () =>
                        _addAccount(context, household, AccountKind.savings),
                  ),
                  InvestasiList(
                    householdId: household.id,
                    items: investments,
                    isLoading: investmentsAsync.isLoading,
                    error: investmentsAsync.error,
                    onAdd: () => _addInvestment(context, household),
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

  Future<void> _addAccount(
    BuildContext context,
    Household household,
    AccountKind kind,
  ) async {
    final draft = await showModalBottomSheet<AccountDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AccountEditSheet(initialKind: kind),
    );
    if (draft == null) return;
    try {
      await ref.read(accountsRepositoryProvider).add(
            householdId: household.id,
            kind: draft.kind,
            label: draft.label,
            hint: draft.hint,
            value: draft.value,
            subKind: draft.subKind,
          );
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menambah rekening');
      }
    }
  }

  Future<void> _addInvestment(
    BuildContext context,
    Household household,
  ) async {
    final draft = await showModalBottomSheet<InvestmentDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const InvestmentEditSheet(),
    );
    if (draft == null) return;
    try {
      await ref.read(investmentsRepositoryProvider).add(
            hid: household.id,
            label: draft.label,
            type: draft.type,
            currentValue: draft.currentValue,
            costBasis: draft.costBasis,
          );
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menambah investasi');
      }
    }
  }
}

/// "Pindah Dana" action pill rendered just below the hero. Hidden for
/// view-only users and when the household has < 2 tracked accounts (no
/// pair to transfer between).
class _TransferCta extends StatelessWidget {
  const _TransferCta();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: FtTapScale(
        scale: 0.985,
        onTap: () => context.push('/transfer/new'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: FtColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FtColors.line, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: FtColors.sky.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: FtColors.sky.withValues(alpha: 0.24),
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.compare_arrows_rounded,
                    size: 16, color: FtColors.sky),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pindah Dana',
                      style: TextStyle(
                        color: FtColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pindahkan saldo antar rekening, dengan biaya opsional',
                      style: TextStyle(color: FtColors.ink3, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: FtColors.ink4),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabsBar extends StatelessWidget {
  const _TabsBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: FtColors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        child: TabBar(
          controller: controller,
          onTap: (_) => FtHaptics.select(),
          // Default in Material 3 is `label` — that makes the indicator hug
          // only the text width, which combined with a 999 radius produced a
          // tall vertical pill. Force the indicator to fill the whole tab.
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
    );
  }
}
