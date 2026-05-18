import 'package:cloud_firestore/cloud_firestore.dart';

import 'account.dart';

/// Cash + savings balances for a household. Stored at
/// `households/{hid}/private/balances`. Read+write require `full` access
/// (see firestore.rules), so the `limited` tier cannot see or change
/// balances — that's the SEC-004 privacy promise that `accessLevelDetail`
/// makes to the user.
class HouseholdBalances {
  final List<Account> cashAccounts;
  final List<Account> savingsAccounts;

  const HouseholdBalances({
    this.cashAccounts = const [],
    this.savingsAccounts = const [],
  });

  static const HouseholdBalances empty = HouseholdBalances();

  Account? accountOf(String id) {
    for (final a in cashAccounts) {
      if (a.id == id) return a;
    }
    for (final a in savingsAccounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'cashAccounts': cashAccounts.map((a) => a.toMap()).toList(),
        'savingsAccounts': savingsAccounts.map((a) => a.toMap()).toList(),
      };

  static HouseholdBalances fromSnapshot(DocumentSnapshot snap) {
    final m = (snap.data() as Map<String, dynamic>?) ?? const {};
    return HouseholdBalances(
      cashAccounts: ((m['cashAccounts'] as List?) ?? const [])
          .map((e) =>
              Account.fromMap(Map<String, dynamic>.from(e as Map), AccountKind.cash))
          .toList(),
      savingsAccounts: ((m['savingsAccounts'] as List?) ?? const [])
          .map((e) => Account.fromMap(
              Map<String, dynamic>.from(e as Map), AccountKind.savings))
          .toList(),
    );
  }

  /// Reference helper for callers that need to read/write the balances doc.
  static DocumentReference<Map<String, dynamic>> ref(
    FirebaseFirestore db,
    String householdId,
  ) =>
      db
          .collection('households')
          .doc(householdId)
          .collection('private')
          .doc('balances');
}
