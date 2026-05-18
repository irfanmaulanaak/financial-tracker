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

  /// Watches recent incomes credited to a given cash/savings account.
  ///
  /// Single-field `where` to dodge composite-index requirements; sort/slice
  /// client-side.
  Stream<List<Income>> watchByAccount({
    required String hid,
    required String accountId,
    int limit = 100,
  }) {
    return _incomes(hid)
        .where('destinationAccountId', isEqualTo: accountId)
        .snapshots()
        .map((s) {
          final rows = s.docs.map(Income.fromSnapshot).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          return rows.length > limit ? rows.sublist(0, limit) : rows;
        });
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
    final householdRef = _householdDoc(householdId);

    await _db.runTransaction((tx) async {
      // Idempotency: deterministic [docId] (recurring runner) skips when
      // the row already exists so concurrent devices don't double-credit
      // the destination account.
      if (docId != null) {
        final iSnap = await tx.get(incomeRef);
        if (iSnap.exists) return;
      }
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

  /// Deletes the income and atomically reverses the destination account by
  /// the same amount (clamped at zero). If the original destination account
  /// no longer exists, deletes the row only.
  Future<void> delete({
    required String householdId,
    required String incomeId,
  }) async {
    final incomeRef = _incomes(householdId).doc(incomeId);
    final householdRef = _householdDoc(householdId);
    await _db.runTransaction((tx) async {
      final iSnap = await tx.get(incomeRef);
      if (!iSnap.exists) return;
      final income = Income.fromSnapshot(iSnap);
      final hSnap = await tx.get(householdRef);
      if (hSnap.exists) {
        final household = Household.fromSnapshot(hSnap);
        final inCash = household.cashAccounts
            .where((a) => a.id == income.destinationAccountId)
            .toList();
        final inSavings = household.savingsAccounts
            .where((a) => a.id == income.destinationAccountId)
            .toList();
        if (inCash.isNotEmpty || inSavings.isNotEmpty) {
          final kind =
              inCash.isNotEmpty ? AccountKind.cash : AccountKind.savings;
          final list = kind == AccountKind.cash
              ? household.cashAccounts
              : household.savingsAccounts;
          final updated = list
              .map((a) => a.id == income.destinationAccountId
                  ? a.copyWith(
                      value: (a.value - income.amount).clamp(0, 1 << 31))
                  : a)
              .toList();
          final field =
              kind == AccountKind.cash ? 'cashAccounts' : 'savingsAccounts';
          tx.update(householdRef, {
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
