import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cicilan.dart';
import '../../core/providers.dart';
import '../accounts/account.dart';
import '../cards/card_repository.dart';
import '../household/household.dart';
import 'expense.dart';

part 'expense_repository_queries.dart';
part 'expense_repository_writes.dart';
part 'expense_repository_helpers.dart';

class ExpenseRepository {
  ExpenseRepository(this._db, this._cards);
  final FirebaseFirestore _db;
  final CardRepository _cards;

  CollectionReference<Map<String, dynamic>> _col(String hid) =>
      _db.collection('households').doc(hid).collection('expenses');
  DocumentReference<Map<String, dynamic>> _cardDoc(String hid, String cardId) =>
      _db.collection('households').doc(hid).collection('cards').doc(cardId);
  CollectionReference<Map<String, dynamic>> _installments(
          String hid, String cardId) =>
      _cardDoc(hid, cardId).collection('installments');

  /// Cash/debit/e-wallet expense.
  ///
  /// When [sourceAccountId] is set, decrements that household cash- or
  /// savings-account by [amount] in the same Firestore transaction that
  /// writes the expense row (mirrors [IncomeRepository.add]). When null
  /// (legacy callers / no accounts seeded yet) the expense is written
  /// without a balance side-effect.
  ///
  /// For credit-card expense use [addCardExpense] or [addCicilanExpense].
  ///
  /// Throws `account_missing` if [sourceAccountId] doesn't match a known
  /// account, `insufficient` if the source has less than [amount].
  Future<String> add({
    required String householdId,
    required int amount,
    required String categoryId,
    required String spentBy,
    required DateTime date,
    String? sourceAccountId,
    String? note,
    bool recurring = false,
    DateTime? now,
    String? docId,
  }) async {
    final ts = now ?? DateTime.now();
    final expenseRef =
        docId != null ? _col(householdId).doc(docId) : _col(householdId).doc();
    final householdRef =
        _db.collection('households').doc(householdId);

    if (sourceAccountId == null) {
      // No source account picked (e.g. household has zero accounts seeded).
      // Write the expense with no balance side-effect.
      final exp = Expense(
        id: expenseRef.id,
        amount: amount,
        categoryId: categoryId,
        note: note,
        spentBy: spentBy,
        date: date,
        recurring: recurring,
        cardId: null,
        installmentPlanId: null,
        sourceAccountId: null,
        createdAt: ts,
        createdBy: spentBy,
      );
      // When a deterministic [docId] is provided (recurring runner), this
      // path needs to be idempotent across devices: if two members open the
      // app on the same day, only one should win. Use a transactional
      // create-if-absent.
      if (docId != null) {
        await _db.runTransaction((tx) async {
          final snap = await tx.get(expenseRef);
          if (snap.exists) return;
          tx.set(expenseRef, exp.toMap());
        });
      } else {
        await expenseRef.set(exp.toMap());
      }
      return expenseRef.id;
    }

    await _db.runTransaction((tx) async {
      // Idempotency: deterministic [docId] callers (recurring runner) skip
      // when the row already exists so concurrent devices don't double-write
      // the row OR double-debit the source account.
      if (docId != null) {
        final eSnap = await tx.get(expenseRef);
        if (eSnap.exists) return;
      }
      final hSnap = await tx.get(householdRef);
      if (!hSnap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(hSnap);
      final inCash = household.cashAccounts
          .where((a) => a.id == sourceAccountId)
          .toList();
      final inSavings = household.savingsAccounts
          .where((a) => a.id == sourceAccountId)
          .toList();
      if (inCash.isEmpty && inSavings.isEmpty) {
        throw StateError('account_missing');
      }
      final kind = inCash.isNotEmpty ? AccountKind.cash : AccountKind.savings;
      final list = kind == AccountKind.cash
          ? household.cashAccounts
          : household.savingsAccounts;
      final source = (kind == AccountKind.cash ? inCash : inSavings).first;
      if (source.value < amount) {
        throw StateError('insufficient');
      }
      final updatedList = list
          .map((a) => a.id == sourceAccountId
              ? a.copyWith(value: a.value - amount)
              : a)
          .toList();
      final field =
          kind == AccountKind.cash ? 'cashAccounts' : 'savingsAccounts';

      tx.set(
        expenseRef,
        Expense(
          id: expenseRef.id,
          amount: amount,
          categoryId: categoryId,
          note: note,
          spentBy: spentBy,
          date: date,
          recurring: recurring,
          cardId: null,
          installmentPlanId: null,
          sourceAccountId: sourceAccountId,
          createdAt: ts,
          createdBy: spentBy,
        ).toMap(),
      );
      tx.update(householdRef, {
        field: updatedList.map((a) => a.toMap()).toList(),
      });
    });
    return expenseRef.id;
  }

  /// Edits an expense atomically. Reverses the old account refund and applies
  /// the new debit in a single transaction. Supports lane swap
  /// (cash <-> credit) and changing the source account or card. Card-side
  /// totals are reconciled via [CardRepository.recalcUsed] post-tx.
  ///
  /// Cicilan rule: when the existing row is a cicilan expense
  /// (`installmentPlanId != null`), only [newCategoryId], [newSpentBy],
  /// [newDate], [newNote], and [newRecurring] are honoured — the lane,
  /// amount, card, and installment plan stay locked. Pass through the
  /// original values for those fields. The repo throws
  /// `cicilan_edit_locked` if the caller tries to change them. When [newDate]
  /// differs from the existing date, the linked installment's `startedAt`
  /// is moved to match, so the BCA-style billing math anchors on the new
  /// transaction date.
  ///
  /// Errors mirror the create paths:
  /// - `expense_missing`, `household_missing`, `card_missing`
  /// - `account_missing` if [newSourceAccountId] doesn't resolve
  /// - `insufficient` if the new source account can't cover the delta
  Future<void> update({
    required String householdId,
    required String expenseId,
    required int newAmount,
    required String newCategoryId,
    required String newSpentBy,
    required DateTime newDate,
    String? newSourceAccountId,
    String? newCardId,
    String? newNote,
    bool newRecurring = false,
  }) async {
    final expenseRef = _col(householdId).doc(expenseId);
    final householdRef = _db.collection('households').doc(householdId);

    final affectedCardIds = <String>{};
    await _db.runTransaction((tx) async {
      final eSnap = await tx.get(expenseRef);
      if (!eSnap.exists) throw StateError('expense_missing');
      final old = Expense.fromSnapshot(eSnap);

      // Cicilan: lock financial fields. Allow only meta edits.
      final isCicilan = old.installmentPlanId != null;
      if (isCicilan) {
        final laneChanged = newCardId != old.cardId ||
            newSourceAccountId != old.sourceAccountId ||
            newAmount != old.amount;
        if (laneChanged) throw StateError('cicilan_edit_locked');
      }

      // Resolve old + new lane refs up front (card refs validated via reads).
      final oldCardRef = old.cardId != null
          ? _cardDoc(householdId, old.cardId!)
          : null;
      final newCardRef = (!isCicilan && newCardId != null)
          ? _cardDoc(householdId, newCardId)
          : null;

      // 1) Read everything we may need.
      final hSnap = await tx.get(householdRef);
      if (!hSnap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(hSnap);

      if (oldCardRef != null) {
        final s = await tx.get(oldCardRef);
        if (s.exists) affectedCardIds.add(old.cardId!);
      }
      if (newCardRef != null && newCardRef.path != oldCardRef?.path) {
        final s = await tx.get(newCardRef);
        if (!s.exists) throw StateError('card_missing');
        affectedCardIds.add(newCardId!);
      }

      // 2) Account-side reversal/debit (card side handled by recalcUsed).
      var cashAccounts = household.cashAccounts;
      var savingsAccounts = household.savingsAccounts;
      if (old.cardId == null && old.sourceAccountId != null) {
        final res = _refundAccount(
          cashAccounts: cashAccounts,
          savingsAccounts: savingsAccounts,
          accountId: old.sourceAccountId!,
          amount: old.amount,
        );
        if (res != null) {
          cashAccounts = res.$1;
          savingsAccounts = res.$2;
        }
      }
      if (!isCicilan && newCardId == null && newSourceAccountId != null) {
        final res = _debitAccount(
          cashAccounts: cashAccounts,
          savingsAccounts: savingsAccounts,
          accountId: newSourceAccountId,
          amount: newAmount,
        );
        cashAccounts = res.$1;
        savingsAccounts = res.$2;
      }

      // 3) Persist updated expense + (optionally) installment startedAt sync.
      final updated = Expense(
        id: old.id,
        amount: isCicilan ? old.amount : newAmount,
        categoryId: newCategoryId,
        paymentMethodId: old.paymentMethodId,
        note: (newNote ?? '').isEmpty ? null : newNote,
        spentBy: newSpentBy,
        date: newDate,
        recurring: isCicilan ? old.recurring : newRecurring,
        cardId: isCicilan ? old.cardId : newCardId,
        installmentPlanId: old.installmentPlanId,
        sourceAccountId: isCicilan ? old.sourceAccountId : newSourceAccountId,
        createdAt: old.createdAt,
        createdBy: old.createdBy,
        reactions: old.reactions,
        review: old.review,
      );
      tx.set(expenseRef, updated.toMap());

      if (isCicilan &&
          old.cardId != null &&
          old.installmentPlanId != null &&
          !_sameDay(old.date, newDate)) {
        final instRef = _installments(householdId, old.cardId!)
            .doc(old.installmentPlanId!);
        tx.update(instRef, {'startedAt': Timestamp.fromDate(newDate)});
      }

      final touchedAccounts = !identical(cashAccounts, household.cashAccounts) ||
          !identical(savingsAccounts, household.savingsAccounts);
      if (touchedAccounts) {
        tx.update(householdRef, {
          'cashAccounts': cashAccounts.map((a) => a.toMap()).toList(),
          'savingsAccounts': savingsAccounts.map((a) => a.toMap()).toList(),
        });
      }
    });
    for (final cid in affectedCardIds) {
      await _cards.recalcUsed(hid: householdId, cardId: cid);
    }
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(
    ref.watch(firestoreProvider),
    ref.watch(cardRepositoryProvider),
  );
});
