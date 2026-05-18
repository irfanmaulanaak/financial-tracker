import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../accounts/account.dart';
import '../accounts/household_balances.dart';
import 'transfer.dart';

/// Firestore writes for the household's `transfers` subcollection.
///
/// `add` performs the move atomically:
///   1. source.value -= amount + fee
///   2. destination.value += amount
///   3. transfers/{tid} is written
///
/// All in one Firestore transaction against `households/{hid}/private/balances`
/// (full-tier only — SEC-004). Throws:
/// - `same_account` — source equals destination
/// - `account_missing` — either id not found in cash/savings accounts
/// - `insufficient` — source has < amount + fee
class TransferRepository {
  TransferRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String hid) =>
      _db.collection('households').doc(hid).collection('transfers');
  DocumentReference<Map<String, dynamic>> _balancesDoc(String hid) =>
      HouseholdBalances.ref(_db, hid);

  Stream<List<Transfer>> watchRecent({
    required String householdId,
    int limit = 25,
  }) {
    return _col(householdId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Transfer.fromSnapshot).toList());
  }

  Future<String> add({
    required String householdId,
    required int amount,
    required int fee,
    required String sourceAccountId,
    required String destinationAccountId,
    required String transferredBy,
    required DateTime date,
    String? note,
    DateTime? now,
  }) async {
    if (sourceAccountId == destinationAccountId) {
      throw StateError('same_account');
    }
    final ts = now ?? DateTime.now();
    final ref = _col(householdId).doc();
    final balancesRef = _balancesDoc(householdId);

    await _db.runTransaction((tx) async {
      final bSnap = await tx.get(balancesRef);
      if (!bSnap.exists) throw StateError('balances_missing');
      final balances = HouseholdBalances.fromSnapshot(bSnap);
      final src = balances.accountOf(sourceAccountId);
      final dst = balances.accountOf(destinationAccountId);
      if (src == null || dst == null) throw StateError('account_missing');
      if (src.value < amount + fee) throw StateError('insufficient');

      // Build new lists per kind. A transfer might be cash→savings, so we
      // may need to update both `cashAccounts` and `savingsAccounts`.
      final newCash = balances.cashAccounts.map((a) {
        if (a.id == src.id && src.kind == AccountKind.cash) {
          return a.copyWith(value: a.value - amount - fee);
        }
        if (a.id == dst.id && dst.kind == AccountKind.cash) {
          return a.copyWith(value: a.value + amount);
        }
        return a;
      }).toList();
      final newSavings = balances.savingsAccounts.map((a) {
        if (a.id == src.id && src.kind == AccountKind.savings) {
          return a.copyWith(value: a.value - amount - fee);
        }
        if (a.id == dst.id && dst.kind == AccountKind.savings) {
          return a.copyWith(value: a.value + amount);
        }
        return a;
      }).toList();

      tx.set(
        ref,
        Transfer(
          id: ref.id,
          amount: amount,
          fee: fee,
          sourceAccountId: sourceAccountId,
          destinationAccountId: destinationAccountId,
          note: note,
          transferredBy: transferredBy,
          date: date,
          createdAt: ts,
          createdBy: transferredBy,
        ).toMap(),
      );

      // Only update arrays that actually changed; some flows touch only one.
      final touchedCash = src.kind == AccountKind.cash ||
          dst.kind == AccountKind.cash;
      final touchedSavings = src.kind == AccountKind.savings ||
          dst.kind == AccountKind.savings;
      tx.update(balancesRef, {
        if (touchedCash)
          'cashAccounts': newCash.map((a) => a.toMap()).toList(),
        if (touchedSavings)
          'savingsAccounts': newSavings.map((a) => a.toMap()).toList(),
      });
    });
    return ref.id;
  }

  /// Reverses the transfer: source += amount + fee, destination -= amount.
  /// Clamped at 0 if the destination has since been spent down.
  Future<void> delete({
    required String householdId,
    required String transferId,
  }) async {
    final ref = _col(householdId).doc(transferId);
    final balancesRef = _balancesDoc(householdId);
    await _db.runTransaction((tx) async {
      final tSnap = await tx.get(ref);
      if (!tSnap.exists) return;
      final t = Transfer.fromSnapshot(tSnap);
      final bSnap = await tx.get(balancesRef);
      if (bSnap.exists) {
        final balances = HouseholdBalances.fromSnapshot(bSnap);
        final src = balances.accountOf(t.sourceAccountId);
        final dst = balances.accountOf(t.destinationAccountId);
        final newCash = balances.cashAccounts.map((a) {
          if (src != null && a.id == src.id && src.kind == AccountKind.cash) {
            return a.copyWith(value: a.value + t.amount + t.fee);
          }
          if (dst != null && a.id == dst.id && dst.kind == AccountKind.cash) {
            return a.copyWith(value: (a.value - t.amount).clamp(0, 1 << 31));
          }
          return a;
        }).toList();
        final newSavings = balances.savingsAccounts.map((a) {
          if (src != null &&
              a.id == src.id &&
              src.kind == AccountKind.savings) {
            return a.copyWith(value: a.value + t.amount + t.fee);
          }
          if (dst != null &&
              a.id == dst.id &&
              dst.kind == AccountKind.savings) {
            return a.copyWith(value: (a.value - t.amount).clamp(0, 1 << 31));
          }
          return a;
        }).toList();
        final touchedCash = src?.kind == AccountKind.cash ||
            dst?.kind == AccountKind.cash;
        final touchedSavings = src?.kind == AccountKind.savings ||
            dst?.kind == AccountKind.savings;
        tx.update(balancesRef, {
          if (touchedCash)
            'cashAccounts': newCash.map((a) => a.toMap()).toList(),
          if (touchedSavings)
            'savingsAccounts': newSavings.map((a) => a.toMap()).toList(),
        });
      }
      tx.delete(ref);
    });
  }
}

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  return TransferRepository(ref.watch(firestoreProvider));
});
