import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../account.dart';
import '../../household/household.dart';
import 'account_tab.dart';

/// Thin alias for the savings branch of [AccountTab]. See [CashTab].
class SavingsTab extends StatelessWidget {
  const SavingsTab({
    super.key,
    required this.household,
    required this.total,
    required this.onAdd,
  });
  final Household household;
  final int total;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => AccountTab(
        household: household,
        kind: AccountKind.savings,
        total: total,
        accent: FtColors.moss,
        subtitle: 'Dana terkunci untuk tujuan dan dana darurat',
        onAdd: onAdd,
      );
}
