import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cicilan.dart';
import '../../core/providers.dart';
import '../accounts/account.dart';
import '../cards/credit_card.dart';
import '../household/household.dart';
import 'expense.dart';

class ExpenseRepository {
  ExpenseRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String hid) =>
      _db.collection('households').doc(hid).collection('expenses');
  DocumentReference<Map<String, dynamic>> _cardDoc(String hid, String cardId) =>
      _db.collection('households').doc(hid).collection('cards').doc(cardId);
  CollectionReference<Map<String, dynamic>> _installments(
          String hid, String cardId) =>
      _cardDoc(hid, cardId).collection('installments');

  Stream<List<Expense>> watchInRange({
    required String householdId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _col(householdId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startInclusive))
        .where('date', isLessThan: Timestamp.fromDate(endExclusive))
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Expense.fromSnapshot).toList());
  }

  Stream<List<Expense>> watchRecent({
    required String householdId,
    int limit = 5,
  }) {
    return _col(householdId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Expense.fromSnapshot).toList());
  }

  Stream<List<Expense>> watchByCategory({
    required String householdId,
    required String categoryId,
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    return _col(householdId)
        .where('categoryId', isEqualTo: categoryId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startInclusive))
        .where('date', isLessThan: Timestamp.fromDate(endExclusive))
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Expense.fromSnapshot).toList());
  }

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

  /// Records a credit-card expense and bumps `card.used` by `amount` in one
  /// transaction. Throws `card_missing` if the card doesn't exist.
  Future<String> addCardExpense({
    required String householdId,
    required int amount,
    required String categoryId,
    required String spentBy,
    required DateTime date,
    required String cardId,
    String? note,
    bool recurring = false,
    DateTime? now,
    String? docId,
  }) async {
    final ts = now ?? DateTime.now();
    final expenseRef =
        docId != null ? _col(householdId).doc(docId) : _col(householdId).doc();
    final cardRef = _cardDoc(householdId, cardId);

    await _db.runTransaction((tx) async {
      // Idempotency: deterministic [docId] (recurring runner) skips when
      // the row already exists so concurrent devices don't double-charge
      // the card.
      if (docId != null) {
        final eSnap = await tx.get(expenseRef);
        if (eSnap.exists) return;
      }
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) throw StateError('card_missing');
      final card = CreditCard.fromSnapshot(cardSnap);

      final exp = Expense(
        id: expenseRef.id,
        amount: amount,
        categoryId: categoryId,
        note: note,
        spentBy: spentBy,
        date: date,
        recurring: recurring,
        cardId: cardId,
        installmentPlanId: null,
        sourceAccountId: null,
        createdAt: ts,
        createdBy: spentBy,
      );
      tx.set(expenseRef, exp.toMap());
      tx.update(cardRef, {'used': card.used + amount});
    });
    return expenseRef.id;
  }

  /// Cicilan flow: computes the plan, writes expense (amount = principal),
  /// creates the installment doc, and bumps `card.used` by the plan's `total`
  /// (the full remaining debt is added to the card immediately, then the
  /// monthly progression / `pay-minimum` reduces it over time).
  ///
  /// Returns the new expense ID.
  Future<({String expenseId, String installmentId, CicilanPlan plan})>
      addCicilanExpense({
    required String householdId,
    required int principal,
    required String categoryId,
    required String spentBy,
    required DateTime date,
    required String cardId,
    required int months,
    required double apr,
    InterestModel model = InterestModel.flat,
    String? note,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final plan = computeCicilan(
      principal: principal,
      months: months,
      apr: apr,
      model: model,
    );
    final expenseRef = _col(householdId).doc();
    final cardRef = _cardDoc(householdId, cardId);
    final installmentRef = _installments(householdId, cardId).doc();

    await _db.runTransaction((tx) async {
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) throw StateError('card_missing');
      final card = CreditCard.fromSnapshot(cardSnap);

      final exp = Expense(
        id: expenseRef.id,
        amount: principal,
        categoryId: categoryId,
        note: note,
        spentBy: spentBy,
        date: date,
        recurring: false,
        cardId: cardId,
        installmentPlanId: installmentRef.id,
        sourceAccountId: null,
        createdAt: ts,
        createdBy: spentBy,
      );
      tx.set(expenseRef, exp.toMap());
      tx.set(installmentRef, {
        'expenseId': expenseRef.id,
        'label': note ?? 'Cicilan ${months}x',
        'total': plan.total,
        'monthly': plan.monthly,
        'monthsTotal': months,
        'monthsPaid': 0,
        'startedAt': Timestamp.fromDate(ts),
      });
      tx.update(cardRef, {'used': card.used + plan.total});
    });
    return (
      expenseId: expenseRef.id,
      installmentId: installmentRef.id,
      plan: plan
    );
  }

  /// Deletes an expense and reverses derived balances atomically:
  /// - cash/debit/e-wallet expense w/ `sourceAccountId`: refunds that
  ///   household cash- or savings-account by the same `amount`
  /// - cash/debit/e-wallet expense w/o source (legacy): removes the row only
  /// - credit-card expense: reverses `card.used` by the same `amount`
  ///   (clamped at zero in case of stale data)
  /// - cicilan expense: deletes the linked installment doc AND reverses
  ///   `card.used` by the plan's `total` (the full remaining debt was added
  ///   to the card when the plan was created, so we reverse the same way)
  Future<void> delete({
    required String householdId,
    required String expenseId,
  }) async {
    final expenseRef = _col(householdId).doc(expenseId);
    final householdRef =
        _db.collection('households').doc(householdId);
    await _db.runTransaction((tx) async {
      final eSnap = await tx.get(expenseRef);
      if (!eSnap.exists) return;
      final expense = Expense.fromSnapshot(eSnap);

      // Cicilan: reverse via the installment plan total (matches the add
      // path that bumps card.used by plan.total).
      if (expense.cardId != null && expense.installmentPlanId != null) {
        final instRef =
            _installments(householdId, expense.cardId!).doc(expense.installmentPlanId!);
        final instSnap = await tx.get(instRef);
        final cardRef = _cardDoc(householdId, expense.cardId!);
        final cardSnap = await tx.get(cardRef);
        if (cardSnap.exists && instSnap.exists) {
          final card = CreditCard.fromSnapshot(cardSnap);
          final plan = Installment.fromSnapshot(instSnap, expense.cardId!);
          final next = (card.used - plan.total).clamp(0, 1 << 31);
          tx.update(cardRef, {'used': next});
        }
        if (instSnap.exists) tx.delete(instRef);
      } else if (expense.cardId != null) {
        // Plain CC expense.
        final cardRef = _cardDoc(householdId, expense.cardId!);
        final cardSnap = await tx.get(cardRef);
        if (cardSnap.exists) {
          final card = CreditCard.fromSnapshot(cardSnap);
          final next = (card.used - expense.amount).clamp(0, 1 << 31);
          tx.update(cardRef, {'used': next});
        }
      } else if (expense.sourceAccountId != null) {
        // Cash/debit/e-wallet expense with a tracked source account: refund
        // it. If the account no longer exists (deleted between record +
        // delete) we just drop the row — same fallback as IncomeRepository.
        final hSnap = await tx.get(householdRef);
        if (hSnap.exists) {
          final household = Household.fromSnapshot(hSnap);
          final inCash = household.cashAccounts
              .where((a) => a.id == expense.sourceAccountId)
              .toList();
          final inSavings = household.savingsAccounts
              .where((a) => a.id == expense.sourceAccountId)
              .toList();
          if (inCash.isNotEmpty || inSavings.isNotEmpty) {
            final kind =
                inCash.isNotEmpty ? AccountKind.cash : AccountKind.savings;
            final list = kind == AccountKind.cash
                ? household.cashAccounts
                : household.savingsAccounts;
            final updated = list
                .map((a) => a.id == expense.sourceAccountId
                    ? a.copyWith(value: a.value + expense.amount)
                    : a)
                .toList();
            final field = kind == AccountKind.cash
                ? 'cashAccounts'
                : 'savingsAccounts';
            tx.update(householdRef, {
              field: updated.map((a) => a.toMap()).toList(),
            });
          }
        }
      }
      tx.delete(expenseRef);
    });
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(firestoreProvider));
});
