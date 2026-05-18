import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../accounts/account.dart';
import '../accounts/household_balances.dart';
import 'income.dart';

class IncomeRepository {
  IncomeRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _householdDoc(String hid) =>
      _db.collection('households').doc(hid);
  CollectionReference<Map<String, dynamic>> _incomes(String hid) =>
      _householdDoc(hid).collection('incomes');
  DocumentReference<Map<String, dynamic>> _balancesDoc(String hid) =>
      HouseholdBalances.ref(_db, hid);

  Stream<List<Income>> watchRecent({required String hid, int limit = 25}) {
    return _incomes(hid)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Income.fromSnapshot).toList());
  }

  /// Records income + bumps the destination account in the same transaction.
  /// Throws `StateError('account_missing')` if destination doesn't exist.
  Future<String> add({
    required String householdId,
    required int amount,
    required IncomeSource source,
    required String destinationAccountId,
    required String receivedBy,
    required DateTime date,
    String? note,
    bool recurring = false,
    DateTime? now,
    String? docId,
  }) async {
    final ts = now ?? DateTime.now();
    final incomeRef = docId != null
        ? _incomes(householdId).doc(docId)
        : _incomes(householdId).doc();
    final balancesRef = _balancesDoc(householdId);

    await _db.runTransaction((tx) async {
      // Idempotency: deterministic [docId] (recurring runner) skips when
      // the row already exists so concurrent devices don't double-credit
      // the destination account.
      if (docId != null) {
        final iSnap = await tx.get(incomeRef);
        if (iSnap.exists) return;
      }
      final bSnap = await tx.get(balancesRef);
      if (!bSnap.exists) throw StateError('balances_missing');
      final balances = HouseholdBalances.fromSnapshot(bSnap);
      final inCash = balances.cashAccounts
          .where((a) => a.id == destinationAccountId)
          .toList();
      final inSavings = balances.savingsAccounts
          .where((a) => a.id == destinationAccountId)
          .toList();
      if (inCash.isEmpty && inSavings.isEmpty) {
        throw StateError('account_missing');
      }
      final kind = inCash.isNotEmpty ? AccountKind.cash : AccountKind.savings;
      final list =
          kind == AccountKind.cash ? balances.cashAccounts : balances.savingsAccounts;
      final updatedList = list
          .map((a) => a.id == destinationAccountId
              ? a.copyWith(value: a.value + amount)
              : a)
          .toList();
      final field = kind == AccountKind.cash ? 'cashAccounts' : 'savingsAccounts';

      tx.set(
        incomeRef,
        Income(
          id: incomeRef.id,
          amount: amount,
          source: source,
          destinationAccountId: destinationAccountId,
          note: note,
          receivedBy: receivedBy,
          date: date,
          recurring: recurring,
          createdAt: ts,
          createdBy: receivedBy,
        ).toMap(),
      );
      tx.update(balancesRef, {
        field: updatedList.map((a) => a.toMap()).toList(),
      });
    });
    return incomeRef.id;
  }

  /// Deletes the income and atomically reverses the destination account by
  /// the same amount (clamped at zero). If the original destination account
  /// no longer exists, deletes the row only.
  Future<void> delete({
    required String householdId,
    required String incomeId,
  }) async {
    final incomeRef = _incomes(householdId).doc(incomeId);
    final balancesRef = _balancesDoc(householdId);
    await _db.runTransaction((tx) async {
      final iSnap = await tx.get(incomeRef);
      if (!iSnap.exists) return;
      final income = Income.fromSnapshot(iSnap);
      final bSnap = await tx.get(balancesRef);
      if (bSnap.exists) {
        final balances = HouseholdBalances.fromSnapshot(bSnap);
        final inCash = balances.cashAccounts
            .where((a) => a.id == income.destinationAccountId)
            .toList();
        final inSavings = balances.savingsAccounts
            .where((a) => a.id == income.destinationAccountId)
            .toList();
        if (inCash.isNotEmpty || inSavings.isNotEmpty) {
          final kind =
              inCash.isNotEmpty ? AccountKind.cash : AccountKind.savings;
          final list = kind == AccountKind.cash
              ? balances.cashAccounts
              : balances.savingsAccounts;
          final updated = list
              .map((a) => a.id == income.destinationAccountId
                  ? a.copyWith(
                      value: (a.value - income.amount).clamp(0, 1 << 31))
                  : a)
              .toList();
          final field =
              kind == AccountKind.cash ? 'cashAccounts' : 'savingsAccounts';
          tx.update(balancesRef, {
            field: updated.map((a) => a.toMap()).toList(),
          });
        }
      }
      tx.delete(incomeRef);
    });
  }
}

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IncomeRepository(ref.watch(firestoreProvider));
});
