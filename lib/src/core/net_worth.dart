/// Pure helpers for net worth aggregation. Caller supplies typed records
/// (extracted from the embedded household arrays + cards subcollection).
library;

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
  const CardBalance({
    required this.id,
    required this.label,
    required this.limit,
    required this.used,
  });

  int get available => (limit - used).clamp(0, limit);
}

class NetWorth {
  final int cash;
  final int savings;
  final int debt;
  const NetWorth({
    required this.cash,
    required this.savings,
    required this.debt,
  });

  int get assets => cash + savings;
  int get total => assets - debt;
}

NetWorth computeNetWorth({
  required Iterable<AccountBalance> cash,
  required Iterable<AccountBalance> savings,
  required Iterable<CardBalance> cards,
}) {
  return NetWorth(
    cash: cash.fold<int>(0, (a, b) => a + b.value),
    savings: savings.fold<int>(0, (a, b) => a + b.value),
    debt: cards.fold<int>(0, (a, b) => a + b.used),
  );
}

/// Applies a balance delta to an account, clamped at 0 (no negative cash).
int applyDelta({required int currentValue, required int delta}) {
  final next = currentValue + delta;
  return next < 0 ? 0 : next;
}
