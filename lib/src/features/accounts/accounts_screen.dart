import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import 'account.dart';
import 'accounts_repository.dart';
import 'widgets/account_edit_sheet.dart';
import 'widgets/account_list.dart';

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
                    AccountList(
                      accounts: household.cashAccounts,
                      kind: AccountKind.cash,
                      householdId: household.id,
                    ),
                    AccountList(
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
    final result = await showModalBottomSheet<AccountDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AccountEditSheet(),
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
