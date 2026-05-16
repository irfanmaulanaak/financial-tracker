import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ids.dart';
import '../../core/net_worth.dart' as nw;
import '../../core/providers.dart';
import '../household/household.dart';
import 'account.dart';

class AccountsRepository {
  AccountsRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String hid) =>
      _db.collection('households').doc(hid);

  String _fieldFor(AccountKind kind) =>
      kind == AccountKind.cash ? 'cashAccounts' : 'savingsAccounts';

  Future<Account> add({
    required String householdId,
    required AccountKind kind,
    required String label,
    String? hint,
    int value = 0,
  }) async {
    final account = Account(
      id: shortId(),
      kind: kind,
      label: label,
      hint: hint,
      value: value,
      sortOrder: 0,
    );
    final ref = _doc(householdId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(snap);
      final list = kind == AccountKind.cash
          ? household.cashAccounts
          : household.savingsAccounts;
      final next = Account(
        id: account.id,
        kind: kind,
        label: account.label,
        hint: account.hint,
        value: account.value,
        sortOrder: list.length,
      );
      tx.update(ref, {
        _fieldFor(kind): [...list.map((a) => a.toMap()), next.toMap()],
      });
    });
    return account;
  }

  Future<void> updateAccount({
    required String householdId,
    required AccountKind kind,
    required String accountId,
    String? label,
    String? hint,
    int? value,
  }) async {
    final ref = _doc(householdId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(snap);
      final list = kind == AccountKind.cash
          ? household.cashAccounts
          : household.savingsAccounts;
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
    final ref = _doc(householdId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(snap);
      final list = kind == AccountKind.cash
          ? household.cashAccounts
          : household.savingsAccounts;
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
    final ref = _doc(householdId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(snap);
      final list = kind == AccountKind.cash
          ? household.cashAccounts
          : household.savingsAccounts;
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
