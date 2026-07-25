import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../account.dart';
import '../../household/household.dart';
import 'account_tab.dart';

/// Thin alias for the cash branch of [AccountTab]. Exists to keep the
/// `AccountsScreen` import list explicit and to mirror the design's tab
/// taxonomy (Tunai / Tabungan).
class CashTab extends StatelessWidget {
  const CashTab({
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
        kind: AccountKind.cash,
        total: total,
        accent: FtColors.ink2,
        subtitle: 'Tunai & rekening cair · siap pakai',
        onAdd: onAdd,
      );
}
