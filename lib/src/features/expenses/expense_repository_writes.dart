part of 'expense_repository.dart';

extension ExpenseRepositoryWrites on ExpenseRepository {
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
        'label': note ?? (months == 1 ? 'Pembelian penuh' : 'Cicilan ${months}x'),
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
          review: old.review,
        ).toMap(),
      );
      touchedCardId = old.cardId;
    });
    if (touchedCardId != null) {
      await _cards.recalcUsed(hid: householdId, cardId: touchedCardId!);
    }
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
