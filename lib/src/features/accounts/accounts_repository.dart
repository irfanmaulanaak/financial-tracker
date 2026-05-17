import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ids.dart';
import '../../core/net_worth.dart' as nw;
import '../../core/providers.dart';
import 'account.dart';
import 'household_balances.dart';

/// Account CRUD against the private balances doc
/// (`households/{hid}/private/balances`). Read+write require `full` tier;
/// limited tier never reaches these methods (UI gates them).
class AccountsRepository {
  AccountsRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _balancesDoc(String hid) =>
      HouseholdBalances.ref(_db, hid);

  String _fieldFor(AccountKind kind) =>
      kind == AccountKind.cash ? 'cashAccounts' : 'savingsAccounts';

  Future<Account> add({
    required String householdId,
    required AccountKind kind,
    required String label,
    String? hint,
    int value = 0,
  }) async {
    final ref = _balancesDoc(householdId);
    final id = shortId();
    final outcome = await _db.runTransaction<Account>((tx) async {
      final snap = await tx.get(ref);
      final balances = snap.exists
          ? HouseholdBalances.fromSnapshot(snap)
          : HouseholdBalances.empty;
      final list =
          kind == AccountKind.cash ? balances.cashAccounts : balances.savingsAccounts;
      final next = Account(
        id: id,
        kind: kind,
        label: label,
        hint: hint,
        value: value,
        sortOrder: list.length,
      );
      final updated = [...list, next];
      final payload = {
        _fieldFor(kind): updated.map((a) => a.toMap()).toList(),
      };
      if (snap.exists) {
        tx.update(ref, payload);
      } else {
        tx.set(ref, {...HouseholdBalances.empty.toMap(), ...payload});
      }
      return next;
    });
    return outcome;
  }

  Future<void> updateAccount({
    required String householdId,
    required AccountKind kind,
    required String accountId,
    String? label,
    String? hint,
    int? value,
  }) async {
    final ref = _balancesDoc(householdId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('balances_missing');
      final balances = HouseholdBalances.fromSnapshot(snap);
      final list = kind == AccountKind.cash
          ? balances.cashAccounts
          : balances.savingsAccounts;
      final exists = list.any((a) => a.id == accountId);
      if (!exists) throw StateError('account_missing');
      final updated = list
          .map((a) => a.id == accountId
              ? a.copyWith(label: label, hint: hint, value: value)
              : a)
          .toList();
      tx.update(ref, {
        _fieldFor(kind): updated.map((a) => a.toMap()).toList(),
      });
    });
  }

  /// Applies a signed delta to an account, clamped at zero.
  Future<void> applyDelta({
    required String householdId,
    required AccountKind kind,
    required String accountId,
    required int delta,
  }) async {
    final ref = _balancesDoc(householdId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('balances_missing');
      final balances = HouseholdBalances.fromSnapshot(snap);
      final list = kind == AccountKind.cash
          ? balances.cashAccounts
          : balances.savingsAccounts;
      final target = list.where((a) => a.id == accountId).toList();
      if (target.isEmpty) throw StateError('account_missing');
      final next = nw.applyDelta(currentValue: target.first.value, delta: delta);
      final updated = list
          .map((a) => a.id == accountId ? a.copyWith(value: next) : a)
          .toList();
      tx.update(ref, {
        _fieldFor(kind): updated.map((a) => a.toMap()).toList(),
      });
    });
  }

  Future<void> delete({
    required String householdId,
    required AccountKind kind,
    required String accountId,
  }) async {
    final ref = _balancesDoc(householdId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('balances_missing');
      final balances = HouseholdBalances.fromSnapshot(snap);
      final list = kind == AccountKind.cash
          ? balances.cashAccounts
          : balances.savingsAccounts;
      final filtered = list.where((a) => a.id != accountId).toList();
      tx.update(ref, {
        _fieldFor(kind): filtered.map((a) => a.toMap()).toList(),
      });
    });
  }
}

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository(ref.watch(firestoreProvider));
});
