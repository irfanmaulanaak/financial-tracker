part of 'expense_repository.dart';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Returns updated (cash, savings) lists with [amount] added back to the
/// account matching [accountId]. Returns null if the account doesn't exist
/// any more (account was deleted between record + edit) — caller drops the
/// refund silently, same fallback as [ExpenseRepository.delete].
(List<Account>, List<Account>)? _refundAccount({
  required List<Account> cashAccounts,
  required List<Account> savingsAccounts,
  required String accountId,
  required int amount,
}) {
  final inCash = cashAccounts.where((a) => a.id == accountId).toList();
  final inSavings = savingsAccounts.where((a) => a.id == accountId).toList();
  if (inCash.isEmpty && inSavings.isEmpty) return null;
  if (inCash.isNotEmpty) {
    return (
      cashAccounts
          .map((a) =>
              a.id == accountId ? a.copyWith(value: a.value + amount) : a)
          .toList(),
      savingsAccounts,
    );
  }
  return (
    cashAccounts,
    savingsAccounts
        .map((a) =>
            a.id == accountId ? a.copyWith(value: a.value + amount) : a)
        .toList(),
  );
}

/// Returns updated (cash, savings) lists with [amount] debited from the
/// account matching [accountId]. Throws `account_missing` or
/// `insufficient` mirroring [ExpenseRepository.add].
(List<Account>, List<Account>) _debitAccount({
  required List<Account> cashAccounts,
  required List<Account> savingsAccounts,
  required String accountId,
  required int amount,
}) {
  final inCash = cashAccounts.where((a) => a.id == accountId).toList();
  final inSavings = savingsAccounts.where((a) => a.id == accountId).toList();
  if (inCash.isEmpty && inSavings.isEmpty) {
    throw StateError('account_missing');
  }
  final source = (inCash.isNotEmpty ? inCash : inSavings).first;
  if (source.value < amount) throw StateError('insufficient');
  if (inCash.isNotEmpty) {
    return (
      cashAccounts
          .map((a) =>
              a.id == accountId ? a.copyWith(value: a.value - amount) : a)
          .toList(),
      savingsAccounts,
    );
  }
  return (
    cashAccounts,
    savingsAccounts
        .map((a) =>
            a.id == accountId ? a.copyWith(value: a.value - amount) : a)
        .toList(),
  );
}
