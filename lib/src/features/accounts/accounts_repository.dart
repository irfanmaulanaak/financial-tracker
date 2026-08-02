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
    AccountSubKind subKind = AccountSubKind.bank,
  }) async {
    final account = Account(
      id: shortId(),
      kind: kind,
      subKind: subKind,
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
        subKind: subKind,
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

  /// Updates an account in place when [newKind] is null or matches [kind].
  /// When [newKind] differs, atomically moves the row to the other array,
  /// preserving id / value / label / hint. Moving to savings drops the
  /// subKind; moving back to cash defaults subKind to `bank`.
  Future<void> updateAccount({
    required String householdId,
    required AccountKind kind,
    required String accountId,
    String? label,
    String? hint,
    int? value,
    AccountSubKind? subKind,
    AccountKind? newKind,
    bool? liquid,
  }) async {
    final ref = _doc(householdId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(snap);
      final fromList = kind == AccountKind.cash
          ? household.cashAccounts
          : household.savingsAccounts;
      final existing = fromList.where((a) => a.id == accountId).toList();
      if (existing.isEmpty) throw StateError('account_missing');

      final targetKind = newKind ?? kind;
      if (targetKind == kind) {
        final updated = fromList
            .map((a) => a.id == accountId
                ? a.copyWith(
                    label: label,
                    hint: hint,
                    value: value,
                    subKind: subKind,
                    liquid: liquid,
                  )
                : a)
            .toList();
        tx.update(ref, {
          _fieldFor(kind): updated.map((a) => a.toMap()).toList(),
        });
      } else {
        final src = existing.first;
        final remaining = fromList.where((a) => a.id != accountId).toList();
        final toList = targetKind == AccountKind.cash
            ? household.cashAccounts
            : household.savingsAccounts;
        final moved = Account(
          id: src.id,
          kind: targetKind,
          subKind: targetKind == AccountKind.cash
              ? (subKind ?? AccountSubKind.bank)
              : AccountSubKind.bank,
          label: label ?? src.label,
          hint: hint ?? src.hint,
          value: value ?? src.value,
          sortOrder: toList.length,
        );
        tx.update(ref, {
          _fieldFor(kind): remaining.map((a) => a.toMap()).toList(),
          _fieldFor(targetKind): [
            ...toList.map((a) => a.toMap()),
            moved.toMap(),
          ],
        });
      }
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
