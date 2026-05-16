import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cicilan.dart';
import '../../core/providers.dart';
import '../cards/credit_card.dart';
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

  /// Cash/debit/e-wallet expense — single write, no balance side-effect.
  /// For credit-card expense use [addCardExpense] or [addCicilanExpense].
  Future<String> add({
    required String householdId,
    required int amount,
    required String categoryId,
    required String paymentMethodId,
    required String spentBy,
    required DateTime date,
    String? note,
    bool recurring = false,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final ref = _col(householdId).doc();
    final exp = Expense(
      id: ref.id,
      amount: amount,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      note: note,
      spentBy: spentBy,
      date: date,
      recurring: recurring,
      cardId: null,
      installmentPlanId: null,
      createdAt: ts,
      createdBy: spentBy,
    );
    await ref.set(exp.toMap());
    return ref.id;
  }

  /// Records a credit-card expense and bumps `card.used` by `amount` in one
  /// transaction. Throws `card_missing` if the card doesn't exist.
  Future<String> addCardExpense({
    required String householdId,
    required int amount,
    required String categoryId,
    required String paymentMethodId,
    required String spentBy,
    required DateTime date,
    required String cardId,
    String? note,
    bool recurring = false,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final expenseRef = _col(householdId).doc();
    final cardRef = _cardDoc(householdId, cardId);

    await _db.runTransaction((tx) async {
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) throw StateError('card_missing');
      final card = CreditCard.fromSnapshot(cardSnap);

      final exp = Expense(
        id: expenseRef.id,
        amount: amount,
        categoryId: categoryId,
        paymentMethodId: paymentMethodId,
        note: note,
        spentBy: spentBy,
        date: date,
        recurring: recurring,
        cardId: cardId,
        installmentPlanId: null,
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
    required String paymentMethodId,
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
        paymentMethodId: paymentMethodId,
        note: note,
        spentBy: spentBy,
        date: date,
        recurring: false,
        cardId: cardId,
        installmentPlanId: installmentRef.id,
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

  Future<void> delete({
    required String householdId,
    required String expenseId,
  }) async {
    // NOTE: deletion does not reverse card.used or installment plan. Phase 5
    // can add a "void" action that fully reverses.
    await _col(householdId).doc(expenseId).delete();
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(firestoreProvider));
});
