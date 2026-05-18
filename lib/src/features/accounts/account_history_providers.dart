import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../expenses/expense.dart';
import '../expenses/expense_repository.dart';
import '../incomes/income.dart';
import '../incomes/income_repository.dart';

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
