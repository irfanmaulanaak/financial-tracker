import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cicilan.dart';
import '../../core/providers.dart';
import '../accounts/account.dart';
import '../accounts/household_balances.dart';
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
    final balancesRef = HouseholdBalances.ref(_db, householdId);

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
      final bSnap = await tx.get(balancesRef);
      if (!bSnap.exists) throw StateError('balances_missing');
      final balances = HouseholdBalances.fromSnapshot(bSnap);
      final inCash = balances.cashAccounts
          .where((a) => a.id == sourceAccountId)
          .toList();
      final inSavings = balances.savingsAccounts
          .where((a) => a.id == sourceAccountId)
          .toList();
      if (inCash.isEmpty && inSavings.isEmpty) {
        throw StateError('account_missing');
      }
      final kind = inCash.isNotEmpty ? AccountKind.cash : AccountKind.savings;
      final list = kind == AccountKind.cash
          ? balances.cashAccounts
          : balances.savingsAccounts;
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
      tx.update(balancesRef, {
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

  /// Edits an expense atomically. Reverses the old balance side-effect
  /// (account refund or `card.used` reduction) and applies the new one in
  /// a single transaction. Supports lane swap (cash <-> credit) and changing
  /// the source account or card.
  ///
  /// Cicilan rule: when the existing row is a cicilan expense
  /// (`installmentPlanId != null`), only [newCategoryId], [newSpentBy],
  /// [newDate], [newNote], and [newRecurring] are honoured — the lane,
  /// amount, card, and installment plan stay locked. Pass through the
  /// original values for those fields. The repo throws
  /// `cicilan_edit_locked` if the caller tries to change them.
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
    final balancesRef = HouseholdBalances.ref(_db, householdId);

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

      // Resolve old + new lane refs up front.
      final oldCardRef = old.cardId != null
          ? _cardDoc(householdId, old.cardId!)
          : null;
      final newCardRef = (!isCicilan && newCardId != null)
          ? _cardDoc(householdId, newCardId)
          : null;

      // 1) Read everything we may need.
      final touchesAccounts = old.sourceAccountId != null ||
          (!isCicilan && newSourceAccountId != null);
      HouseholdBalances? balances;
      if (touchesAccounts) {
        final bSnap = await tx.get(balancesRef);
        if (!bSnap.exists) throw StateError('balances_missing');
        balances = HouseholdBalances.fromSnapshot(bSnap);
      }

      CreditCard? oldCard;
      if (oldCardRef != null) {
        final s = await tx.get(oldCardRef);
        if (s.exists) oldCard = CreditCard.fromSnapshot(s);
      }
      CreditCard? newCard;
      if (newCardRef != null && newCardRef.path != oldCardRef?.path) {
        final s = await tx.get(newCardRef);
        if (!s.exists) throw StateError('card_missing');
        newCard = CreditCard.fromSnapshot(s);
      }

      // 2) Reverse old account/card effect in-memory.
      var cashAccounts = balances?.cashAccounts ?? const <Account>[];
      var savingsAccounts = balances?.savingsAccounts ?? const <Account>[];
      final cardUsed = <String, int>{};
      if (oldCard != null) cardUsed[oldCard.id] = oldCard.used;
      if (newCard != null) cardUsed[newCard.id] = newCard.used;

      if (old.cardId != null && !isCicilan) {
        // Plain CC: reverse oldAmount.
        final cur = cardUsed[old.cardId!] ?? 0;
        cardUsed[old.cardId!] = (cur - old.amount).clamp(0, 1 << 31).toInt();
      } else if (old.sourceAccountId != null) {
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

      // 3) Apply new side-effect. Cicilan keeps the original lane untouched
      //    (we already reversed nothing for cicilan above).
      if (!isCicilan) {
        if (newCardId != null) {
          final cur = cardUsed[newCardId] ?? 0;
          cardUsed[newCardId] = cur + newAmount;
        } else if (newSourceAccountId != null) {
          final res = _debitAccount(
            cashAccounts: cashAccounts,
            savingsAccounts: savingsAccounts,
            accountId: newSourceAccountId,
            amount: newAmount,
          );
          cashAccounts = res.$1;
          savingsAccounts = res.$2;
        }
      }

      // 4) Persist updated expense + balances.
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
      );
      tx.set(expenseRef, updated.toMap());

      if (balances != null) {
        final touchedAccounts =
            !identical(cashAccounts, balances.cashAccounts) ||
                !identical(savingsAccounts, balances.savingsAccounts);
        if (touchedAccounts) {
          tx.update(balancesRef, {
            'cashAccounts': cashAccounts.map((a) => a.toMap()).toList(),
            'savingsAccounts': savingsAccounts.map((a) => a.toMap()).toList(),
          });
        }
      }
      cardUsed.forEach((cid, used) {
        tx.update(_cardDoc(householdId, cid), {'used': used});
      });
    });
  }

  /// Returns updated (cash, savings) lists with [amount] added back to the
  /// account matching [accountId]. Returns null if the account doesn't exist
  /// any more (account was deleted between record + edit) — caller drops the
  /// refund silently, same fallback as [delete].
  (List<Account>, List<Account>)? _refundAccount({
    required List<Account> cashAccounts,
    required List<Account> savingsAccounts,
    required String accountId,
    required int amount,
  }) {
    final inCash = cashAccounts.where((a) => a.id == accountId).toList();
    final inSavings = savingsAccounts.where((a) => a.id == accountId).toList();
    if (inCash.isEmpty && inSavings.isEmpty) return null;
    if (inCash.isNotEmpty) {
      return (
        cashAccounts
            .map((a) =>
                a.id == accountId ? a.copyWith(value: a.value + amount) : a)
            .toList(),
        savingsAccounts,
      );
    }
    return (
      cashAccounts,
      savingsAccounts
          .map((a) =>
              a.id == accountId ? a.copyWith(value: a.value + amount) : a)
          .toList(),
    );
  }

  /// Returns updated (cash, savings) lists with [amount] debited from the
  /// account matching [accountId]. Throws `account_missing` or
  /// `insufficient` mirroring [add].
  (List<Account>, List<Account>) _debitAccount({
    required List<Account> cashAccounts,
    required List<Account> savingsAccounts,
    required String accountId,
    required int amount,
  }) {
    final inCash = cashAccounts.where((a) => a.id == accountId).toList();
    final inSavings = savingsAccounts.where((a) => a.id == accountId).toList();
    if (inCash.isEmpty && inSavings.isEmpty) {
      throw StateError('account_missing');
    }
    final source = (inCash.isNotEmpty ? inCash : inSavings).first;
    if (source.value < amount) throw StateError('insufficient');
    if (inCash.isNotEmpty) {
      return (
        cashAccounts
            .map((a) =>
                a.id == accountId ? a.copyWith(value: a.value - amount) : a)
            .toList(),
        savingsAccounts,
      );
    }
    return (
      cashAccounts,
      savingsAccounts
          .map((a) =>
              a.id == accountId ? a.copyWith(value: a.value - amount) : a)
          .toList(),
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
    final balancesRef = HouseholdBalances.ref(_db, householdId);
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
        final bSnap = await tx.get(balancesRef);
        if (bSnap.exists) {
          final balances = HouseholdBalances.fromSnapshot(bSnap);
          final inCash = balances.cashAccounts
              .where((a) => a.id == expense.sourceAccountId)
              .toList();
          final inSavings = balances.savingsAccounts
              .where((a) => a.id == expense.sourceAccountId)
              .toList();
          if (inCash.isNotEmpty || inSavings.isNotEmpty) {
            final kind =
                inCash.isNotEmpty ? AccountKind.cash : AccountKind.savings;
            final list = kind == AccountKind.cash
                ? balances.cashAccounts
                : balances.savingsAccounts;
            final updated = list
                .map((a) => a.id == expense.sourceAccountId
                    ? a.copyWith(value: a.value + expense.amount)
                    : a)
                .toList();
            final field = kind == AccountKind.cash
                ? 'cashAccounts'
                : 'savingsAccounts';
            tx.update(balancesRef, {
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
