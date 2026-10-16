import 'package:cloud_firestore/cloud_firestore.dart';

import '../accounts/account.dart';
import '../household/household.dart';

/// Debits `amount` from the cash- or savings-account matching
/// `sourceAccountId` and writes the updated array back via [tx]. Throws
/// `account_missing` or `insufficient`.
///
/// Pure helper for [CardRepository]: it touches only the data passed in, so
/// it lives in its own file rather than on the repository instance.
void debitAccountTx({
  required Transaction tx,
  required DocumentReference<Map<String, dynamic>> householdRef,
  required Household household,
  required String sourceAccountId,
  required int amount,
}) {
  final inCash = household.cashAccounts
      .where((a) => a.id == sourceAccountId)
      .toList();
  final inSavings = household.savingsAccounts
      .where((a) => a.id == sourceAccountId)
      .toList();
  if (inCash.isEmpty && inSavings.isEmpty) {
    throw StateError('account_missing');
  }
  final kind = inCash.isNotEmpty ? AccountKind.cash : AccountKind.savings;
  final list = kind == AccountKind.cash
      ? household.cashAccounts
      : household.savingsAccounts;
  final source = (kind == AccountKind.cash ? inCash : inSavings).first;
  if (source.value < amount) throw StateError('insufficient');
  final updated = list
      .map((a) => a.id == sourceAccountId
          ? a.copyWith(value: a.value - amount)
          : a)
      .toList();
  final field =
      kind == AccountKind.cash ? 'cashAccounts' : 'savingsAccounts';
  tx.update(householdRef, {
    field: updated.map((a) => a.toMap()).toList(),
  });
}
