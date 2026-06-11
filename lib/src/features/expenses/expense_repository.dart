import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cicilan.dart';
import '../../core/providers.dart';
import '../accounts/account.dart';
import '../cards/card_repository.dart';
import '../household/household.dart';
import 'expense.dart';

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

  /// All recurring-flagged rows since [since]. Same query shape as the
  /// recurring runner — served by the deployed recurring+date composite
  /// index. Powers the "Langganan & Rutin" screen.
  Stream<List<Expense>> watchRecurringSince({
    required String householdId,
    required DateTime since,
  }) {
    return _col(householdId)
        .where('recurring', isEqualTo: true)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .snapshots()
        .map((s) => s.docs.map(Expense.fromSnapshot).toList());
  }

  /// Watches the most recent **non-cicilan** expenses for a single card.
  ///
  /// Server-side query is just `where('cardId', isEqualTo: cardId)` so we
  /// only need Firestore's auto-created single-field index — combining it
  /// with `orderBy('date')` would require a deployed composite index and
  /// the stream silently stalls until the index is built. Sort + slice
  /// happen client-side; for a 2–5 person household the per-card row count
  /// is small enough that this is cheap.
  Stream<List<Expense>> watchByCard({
    required String householdId,
    required String cardId,
    int limit = 20,
  }) {
    return _col(householdId)
        .where('cardId', isEqualTo: cardId)
        .snapshots()
        .map((s) {
          final rows = s.docs
              .map(Expense.fromSnapshot)
              .where((e) => e.installmentPlanId == null)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          return rows.length > limit ? rows.sublist(0, limit) : rows;
        });
  }

  /// Watches recent expenses paid from a given cash/savings account.
  ///
  /// Server-side query is a single `where('sourceAccountId', isEqualTo: ...)`
  /// to avoid needing a composite index. Sort by date desc and slice
  /// client-side — for a 2–5 person household per-account row counts are
  /// small enough that this is cheap.
  Stream<List<Expense>> watchByAccount({
    required String householdId,
    required String accountId,
    int limit = 100,
  }) {
    return _col(householdId)
        .where('sourceAccountId', isEqualTo: accountId)
        .snapshots()
        .map((s) {
          final rows = s.docs.map(Expense.fromSnapshot).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          return rows.length > limit ? rows.sublist(0, limit) : rows;
        });
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

  /// Records a credit-card expense. `card.used` is reconciled post-tx via
  /// [CardRepository.recalcUsed] so the BCA-style formula stays the single
  /// source of truth. Throws `card_missing` if the card doesn't exist.
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

    final wrote = await _db.runTransaction<bool>((tx) async {
      // Idempotency: deterministic [docId] (recurring runner) skips when
      // the row already exists so concurrent devices don't double-charge
      // the card.
      if (docId != null) {
        final eSnap = await tx.get(expenseRef);
        if (eSnap.exists) return false;
      }
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) throw StateError('card_missing');

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
      return true;
    });
    if (wrote) await _cards.recalcUsed(hid: householdId, cardId: cardId);
    return expenseRef.id;
  }

  /// Cicilan flow: computes the plan, writes expense (amount = principal),
  /// creates the installment doc with `startedAt = date` (so the BCA-style
  /// `cicilanBlocked` math anchors on the transaction date), then triggers
  /// [CardRepository.recalcUsed] post-tx so `card.used` reflects the new
  /// blocked amount.
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
        'startedAt': Timestamp.fromDate(date),
      });
    });
    await _cards.recalcUsed(hid: householdId, cardId: cardId);
    return (
      expenseId: expenseRef.id,
      installmentId: installmentRef.id,
      plan: plan
    );
  }

  /// Edits an existing cicilan plan in one transaction. Recomputes the plan
  /// with the new principal/months/apr, resets `monthsPaid` to 0, rewrites
  /// the linked expense's `amount`. Optional [newDate] retroactively shifts
  /// the cicilan's `startedAt` (and the expense `date`) so the BCA-style
  /// `monthsBilled` math lines up with the bank's transaction date.
  ///
  /// Card swap is NOT supported here (cicilan stays on its original card).
  /// All other meta (category, note, spentBy, recurring) is preserved.
  /// `card.used` is reconciled via [CardRepository.recalcUsed] after the tx.
  ///
  /// Throws `expense_missing`, `installment_missing`, or `card_missing`.
  Future<void> updateCicilanPlan({
    required String householdId,
    required String expenseId,
    required int newPrincipal,
    required int newMonths,
    required double newApr,
    String? newLabel,
    DateTime? newDate,
    InterestModel model = InterestModel.flat,
  }) async {
    final newPlan = computeCicilan(
      principal: newPrincipal,
      months: newMonths,
      apr: newApr,
      model: model,
    );
    final expenseRef = _col(householdId).doc(expenseId);
    String? touchedCardId;
    await _db.runTransaction((tx) async {
      final eSnap = await tx.get(expenseRef);
      if (!eSnap.exists) throw StateError('expense_missing');
      final old = Expense.fromSnapshot(eSnap);
      if (old.cardId == null || old.installmentPlanId == null) {
        throw StateError('expense_missing');
      }
      final cardRef = _cardDoc(householdId, old.cardId!);
      final instRef =
          _installments(householdId, old.cardId!).doc(old.installmentPlanId!);
      final instSnap = await tx.get(instRef);
      if (!instSnap.exists) throw StateError('installment_missing');
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) throw StateError('card_missing');

      final effectiveDate = newDate ?? old.date;
      tx.update(instRef, {
        'label': ?newLabel,
        'total': newPlan.total,
        'monthly': newPlan.monthly,
        'monthsTotal': newMonths,
        'monthsPaid': 0,
        if (newDate != null) 'startedAt': Timestamp.fromDate(newDate),
      });
      tx.set(
        expenseRef,
        Expense(
          id: old.id,
          amount: newPrincipal,
          categoryId: old.categoryId,
          paymentMethodId: old.paymentMethodId,
          note: old.note,
          spentBy: old.spentBy,
          date: effectiveDate,
          recurring: old.recurring,
          cardId: old.cardId,
          installmentPlanId: old.installmentPlanId,
          sourceAccountId: old.sourceAccountId,
          createdAt: old.createdAt,
          createdBy: old.createdBy,
          reactions: old.reactions,
        ).toMap(),
      );
      touchedCardId = old.cardId;
    });
    if (touchedCardId != null) {
      await _cards.recalcUsed(hid: householdId, cardId: touchedCardId!);
    }
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

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
  /// - credit-card expense: row + linked installment (if any) are deleted in
  ///   the tx; `card.used` is reconciled via [CardRepository.recalcUsed]
  ///   post-tx so the BCA-style formula stays the single source of truth.
  Future<void> delete({
    required String householdId,
    required String expenseId,
  }) async {
    final expenseRef = _col(householdId).doc(expenseId);
    final householdRef =
        _db.collection('households').doc(householdId);
    // Recurring instances live at deterministic doc IDs ("recur_<hash>_<ymd>").
    // Without a tombstone, the runner would re-create the deleted month on
    // the next app launch (the `exists` guard inside `add` only catches
    // in-flight duplicates, not past deletions). Write a tombstone so the
    // runner skips this date.
    final isRecurringInstance = expenseId.startsWith('recur_');
    final tombstoneRef = isRecurringInstance
        ? _db
            .collection('households')
            .doc(householdId)
            .collection('recurring_tombstones')
            .doc(expenseId)
        : null;
    String? touchedCardId;
    await _db.runTransaction((tx) async {
      final eSnap = await tx.get(expenseRef);
      if (!eSnap.exists) return;
      final expense = Expense.fromSnapshot(eSnap);

      if (expense.cardId != null && expense.installmentPlanId != null) {
        final instRef = _installments(householdId, expense.cardId!)
            .doc(expense.installmentPlanId!);
        final instSnap = await tx.get(instRef);
        if (instSnap.exists) tx.delete(instRef);
        touchedCardId = expense.cardId;
      } else if (expense.cardId != null) {
        touchedCardId = expense.cardId;
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
      if (tombstoneRef != null) {
        tx.set(tombstoneRef, {
          'tombstonedAt': Timestamp.fromDate(DateTime.now()),
          'date': Timestamp.fromDate(expense.date),
        });
      }
    });
    if (touchedCardId != null) {
      await _cards.recalcUsed(hid: householdId, cardId: touchedCardId!);
    }
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(
    ref.watch(firestoreProvider),
    ref.watch(cardRepositoryProvider),
  );
});
