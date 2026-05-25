import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../expenses/expense.dart';
import '../expenses/expense_repository.dart';
import '../incomes/income.dart';
import '../incomes/income_repository.dart';
import '../transfers/transfer.dart';
import '../transfers/transfer_repository.dart';

/// Recent expenses paid from a single cash/savings account. Used by the
/// account detail screen so the user can see what came out of this rekening.
final accountExpensesProvider = StreamProvider.family<
    List<Expense>, ({String hid, String accountId})>((ref, p) {
  return ref.watch(expenseRepositoryProvider).watchByAccount(
        householdId: p.hid,
        accountId: p.accountId,
      );
});

/// Recent incomes credited to a single cash/savings account.
final accountIncomesProvider = StreamProvider.family<
    List<Income>, ({String hid, String accountId})>((ref, p) {
  return ref.watch(incomeRepositoryProvider).watchByAccount(
        hid: p.hid,
        accountId: p.accountId,
      );
});

/// Transfers leaving this account. Rendered as outgoing rows in history.
final accountOutgoingTransfersProvider = StreamProvider.family<
    List<Transfer>, ({String hid, String accountId})>((ref, p) {
  return ref.watch(transferRepositoryProvider).watchBySourceAccount(
        householdId: p.hid,
        accountId: p.accountId,
      );
});

/// Transfers landing in this account. Rendered as incoming rows in history.
final accountIncomingTransfersProvider = StreamProvider.family<
    List<Transfer>, ({String hid, String accountId})>((ref, p) {
  return ref.watch(transferRepositoryProvider).watchByDestinationAccount(
        householdId: p.hid,
        accountId: p.accountId,
      );
});
