import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../accounts/account.dart';
import '../household/household.dart';
import 'income.dart';

class IncomeRepository {
  IncomeRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _householdDoc(String hid) =>
      _db.collection('households').doc(hid);
  CollectionReference<Map<String, dynamic>> _incomes(String hid) =>
      _householdDoc(hid).collection('incomes');

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
  }) async {
    final ts = now ?? DateTime.now();
    final incomeRef = _incomes(householdId).doc();
    final householdRef = _householdDoc(householdId);

    await _db.runTransaction((tx) async {
      final hSnap = await tx.get(householdRef);
      if (!hSnap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(hSnap);
      final inCash = household.cashAccounts
          .where((a) => a.id == destinationAccountId)
          .toList();
      final inSavings = household.savingsAccounts
          .where((a) => a.id == destinationAccountId)
          .toList();
      if (inCash.isEmpty && inSavings.isEmpty) {
        throw StateError('account_missing');
      }
      final kind = inCash.isNotEmpty ? AccountKind.cash : AccountKind.savings;
      final list =
          kind == AccountKind.cash ? household.cashAccounts : household.savingsAccounts;
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
      tx.update(householdRef, {
        field: updatedList.map((a) => a.toMap()).toList(),
      });
    });
    return incomeRef.id;
  }

  Future<void> delete({
    required String householdId,
    required String incomeId,
  }) async {
    // Deletion does NOT reverse the destination-account bump in MVP. Users
    // can adjust manually via the edit-account sheet. (Reversal would need
    // the original destination + amount; trade-off for simplicity.)
    await _incomes(householdId).doc(incomeId).delete();
  }
}

final incomeRepositoryProvider = Provider<IncomeRepository>((ref) {
  return IncomeRepository(ref.watch(firestoreProvider));
});
