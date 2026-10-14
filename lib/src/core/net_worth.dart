/// Pure helpers for net worth aggregation. Caller supplies typed records
/// (extracted from the embedded household arrays + cards subcollection).
library;

import 'cicilan.dart';

class AccountBalance {
  final String id;
  final String label;
  final int value;
  const AccountBalance({
    required this.id,
    required this.label,
    required this.value,
  });
}

class CardBalance {
  final String id;
  final String label;
  final int limit;
  final int used;

  /// True remaining obligation (full unpaid cicilan remainder + unpaid plain
  /// charges). Drives [available]; defaults to [used] for callers that only
  /// care about net-worth debt. See [availableLimit].
  final int outstanding;
  const CardBalance({
    required this.id,
    required this.label,
    required this.limit,
    required this.used,
    int? outstanding,
  }) : outstanding = outstanding ?? used;

  int get available => availableLimit(limit: limit, outstanding: outstanding);
}

class NetWorth {
  final int cash;
  final int savings;
  final int investments;
  final int debt;
  const NetWorth({
    required this.cash,
    required this.savings,
    required this.investments,
    required this.debt,
  });

  int get assets => cash + savings + investments;
  int get total => assets - debt;
}

NetWorth computeNetWorth({
  required Iterable<AccountBalance> cash,
  required Iterable<AccountBalance> savings,
  required Iterable<CardBalance> cards,
  int investments = 0,
  int otherDebt = 0,
}) {
  return NetWorth(
    cash: cash.fold<int>(0, (a, b) => a + b.value),
    savings: savings.fold<int>(0, (a, b) => a + b.value),
    investments: investments,
    debt: cards.fold<int>(0, (a, b) => a + b.used) + otherDebt,
  );
}

/// Applies a balance delta to an account, clamped at 0 (no negative cash).
int applyDelta({required int currentValue, required int delta}) {
  final next = currentValue + delta;
  return next < 0 ? 0 : next;
}
