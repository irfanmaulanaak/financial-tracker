import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cicilan.dart';
import '../../core/providers.dart';
import '../accounts/account.dart';
import '../expenses/expense.dart';
import '../household/household.dart';
import 'credit_card.dart';

class CardRepository {
  CardRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _cards(String hid) =>
      _db.collection('households').doc(hid).collection('cards');
  CollectionReference<Map<String, dynamic>> _installments(
          String hid, String cardId) =>
      _cards(hid).doc(cardId).collection('installments');

  Stream<List<CreditCard>> watchAll(String hid) {
    return _cards(hid).snapshots().map(
          (s) => s.docs.map(CreditCard.fromSnapshot).toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
        );
  }

  Stream<CreditCard?> watchOne({required String hid, required String cardId}) {
    return _cards(hid)
        .doc(cardId)
        .snapshots()
        .map((s) => s.exists ? CreditCard.fromSnapshot(s) : null);
  }

  Stream<List<Installment>> watchInstallments({
    required String hid,
    required String cardId,
  }) {
    return _installments(hid, cardId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Installment.fromSnapshot(d, cardId)).toList());
  }

  Future<String> addCard({
    required String hid,
    required String ownerId,
    required String label,
    String last4 = '',
    required int limit,
    int used = 0,
    int dueDay = 25,
    int billingDay = 12,
    double apr = 0.18,
    String accent = '#3B82F6',
    double minPaymentPct = 0.10,
  }) async {
    final ref = _cards(hid).doc();
    final card = CreditCard(
      id: ref.id,
      ownerId: ownerId,
      label: label,
      last4: last4,
      limit: limit,
      used: used,
      // No cicilan yet at creation, so the true debt equals `used`.
      outstanding: used,
      dueDay: dueDay,
      billingDay: billingDay,
      apr: apr,
      accent: accent,
      minPaymentPct: minPaymentPct,
    );
    await ref.set(card.toMap());
    return ref.id;
  }

  Future<void> updateCard({
    required String hid,
    required String cardId,
    String? label,
    String? last4,
    int? limit,
    int? dueDay,
    int? billingDay,
    double? apr,
    String? accent,
    double? minPaymentPct,
  }) async {
    await _cards(hid).doc(cardId).update({
      'label': ?label,
      'last4': ?last4,
      'limit': ?limit,
      'dueDay': ?dueDay,
      'billingDay': ?billingDay,
      'apr': ?apr,
      'accent': ?accent,
      'minPaymentPct': ?minPaymentPct,
    });
  }

  /// Deletes a card. Refuses when the card still has outstanding debt
  /// (`used > 0`) or any active installment plan (`monthsPaid < monthsTotal`).
  /// Otherwise cascades installment docs (historical, all-paid) and then
  /// deletes the card root.
  ///
  /// Throws:
  /// - `StateError('card_missing')` if the card doesn't exist.
  /// - `StateError('card_has_balance')` if `used > 0`.
  /// - `StateError('card_has_active_installments')` if any plan isn't done.
  Future<void> deleteCard({required String hid, required String cardId}) async {
    final cardRef = _cards(hid).doc(cardId);
    final cardSnap = await cardRef.get();
    if (!cardSnap.exists) throw StateError('card_missing');
    final card = CreditCard.fromSnapshot(cardSnap);
    if (card.used > 0) throw StateError('card_has_balance');

    final instSnap = await _installments(hid, cardId).get();
    final hasActive = instSnap.docs.any((d) {
      final inst = Installment.fromSnapshot(d, cardId);
      return !inst.isComplete;
    });
    if (hasActive) throw StateError('card_has_active_installments');

    if (instSnap.docs.isNotEmpty) {
      final batch = _db.batch();
      for (final d in instSnap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    await cardRef.delete();
  }

  /// Applies the card's minimum payment: debits the minimum from the chosen
  /// household account and books it against plain charges (`plainPaid`).
  /// The card's totals are reconciled by [recalcUsed] after the tx. Returns
  /// the amount applied. Throws `card_missing`, `household_missing`,
  /// `account_missing`, or `insufficient`.
  Future<int> payMinimum({
    required String hid,
    required String cardId,
    required String sourceAccountId,
  }) async {
    final cardRef = _cards(hid).doc(cardId);
    final householdRef = _db.collection('households').doc(hid);
    final amount = await _db.runTransaction<int>((tx) async {
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) throw StateError('card_missing');
      final card = CreditCard.fromSnapshot(cardSnap);
      final amount = minimumPayment(
        balance: card.used,
        minPaymentPct: card.minPaymentPct,
      );
      if (amount <= 0) return 0;
      final hSnap = await tx.get(householdRef);
      if (!hSnap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(hSnap);
      _debitAccountTx(
        tx: tx,
        householdRef: householdRef,
        household: household,
        sourceAccountId: sourceAccountId,
        amount: amount,
      );
      tx.update(cardRef, {'plainPaid': card.plainPaid + amount});
      return amount;
    });
    if (amount > 0) await recalcUsed(hid: hid, cardId: cardId);
    return amount;
  }

  /// Pays a user-defined `amount` against the card from `sourceAccountId`,
  /// booked against plain charges (`plainPaid` — cicilan months are paid via
  /// their own flows). Used by the "Jumlah Lain" / custom-amount flow in
  /// [PayCardSheet]. Returns the amount applied (capped to `card.used`).
  Future<int> payCustom({
    required String hid,
    required String cardId,
    required String sourceAccountId,
    required int amount,
  }) async {
    if (amount <= 0) return 0;
    final cardRef = _cards(hid).doc(cardId);
    final householdRef = _db.collection('households').doc(hid);
    final applied = await _db.runTransaction<int>((tx) async {
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) throw StateError('card_missing');
      final card = CreditCard.fromSnapshot(cardSnap);
      final applied = amount > card.used ? card.used : amount;
      if (applied <= 0) return 0;
      final hSnap = await tx.get(householdRef);
      if (!hSnap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(hSnap);
      _debitAccountTx(
        tx: tx,
        householdRef: householdRef,
        household: household,
        sourceAccountId: sourceAccountId,
        amount: applied,
      );
      tx.update(cardRef, {'plainPaid': card.plainPaid + applied});
      return applied;
    });
    if (applied > 0) await recalcUsed(hid: hid, cardId: cardId);
    return applied;
  }

  /// Pays this month's bill the way the bank statement does: one `monthly`
  /// per cicilan that has been BILLED but not yet paid (a cicilan opened
  /// after the last statement date isn't charged yet) plus the card's plain
  /// (non-cicilan) unpaid charges. Debits the chosen account, advances each
  /// billed installment's `monthsPaid` by one, and books the plain portion
  /// to `plainPaid` — all in a single transaction. [recalcUsed] runs post-tx
  /// to reconcile both totals. Returns the total amount paid.
  Future<int> payMonthlyBill({
    required String hid,
    required String cardId,
    required String sourceAccountId,
    DateTime? today,
  }) async {
    final now = today ?? DateTime.now();
    final cardRef = _cards(hid).doc(cardId);
    final householdRef = _db.collection('households').doc(hid);
    // Installment docs can't be queried inside a transaction (no
    // collection reads), so we list active plans up front and then
    // re-read each by reference inside the txn for the consistent view.
    final instSnap = await _installments(hid, cardId).get();
    final activeRefs = <DocumentReference<Map<String, dynamic>>>[];
    for (final d in instSnap.docs) {
      final inst = Installment.fromSnapshot(d, cardId);
      if (!inst.isComplete) activeRefs.add(d.reference);
    }
    final amount = await _db.runTransaction<int>((tx) async {
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) throw StateError('card_missing');
      final card = CreditCard.fromSnapshot(cardSnap);

      var monthlyDue = 0;
      var remainingDue = 0;
      final billedPlans = <(DocumentReference<Map<String, dynamic>>, Installment)>[];
      for (final ref in activeRefs) {
        final snap = await tx.get(ref);
        if (!snap.exists) continue;
        final inst = Installment.fromSnapshot(snap, cardId);
        if (inst.isComplete) continue;
        remainingDue += inst.remainingAmount;
        final billed = computeMonthsBilled(
          startedAt: inst.startedAt,
          today: now,
          billingDay: card.billingDay,
        );
        // Only months the bank has actually rolled into a statement are due.
        if (billed <= inst.monthsPaid) continue;
        monthlyDue += inst.monthly;
        billedPlans.add((ref, inst));
      }
      // `outstanding` = plain + Σ remaining, so this subtraction is exact.
      // (The old `used`-based math under-counted plain charges whenever a
      // cicilan month hadn't been billed yet.)
      final plainCharges =
          (card.outstanding - remainingDue).clamp(0, card.outstanding);
      final amount = monthlyDue + plainCharges;
      if (amount <= 0) return 0;

      final hSnap = await tx.get(householdRef);
      if (!hSnap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(hSnap);
      _debitAccountTx(
        tx: tx,
        householdRef: householdRef,
        household: household,
        sourceAccountId: sourceAccountId,
        amount: amount,
      );
      for (final (ref, inst) in billedPlans) {
        tx.update(ref, {'monthsPaid': inst.monthsPaid + 1});
      }
      if (plainCharges > 0) {
        tx.update(cardRef, {'plainPaid': card.plainPaid + plainCharges});
      }
      return amount;
    });
    if (amount > 0) await recalcUsed(hid: hid, cardId: cardId);
    return amount;
  }

  /// Recomputes the card's two debt figures (see [cardDebtTotals]):
  ///
  ///   * `used` — BCA-display "limit terpakai". Moves on the statement date,
  ///     mirroring the bank app.
  ///   * `outstanding` — true remaining obligation (full unpaid cicilan
  ///     remainder + unpaid plain charges). Date-independent; this is what
  ///     net worth / health score count as debt, so statement day causes no
  ///     net-worth jump and paying cicilan is net-worth-neutral.
  ///
  /// Reads expenses + installments + the card outside the transaction
  /// (Firestore txns can't run queries), then writes both totals in a
  /// single update. Acceptable race-condition surface for a 2–5 user
  /// household. Returns the new `used`.
  Future<int> recalcUsed({
    required String hid,
    required String cardId,
    DateTime? today,
  }) async {
    final now = today ?? DateTime.now();
    final cardRef = _cards(hid).doc(cardId);
    final cardSnap = await cardRef.get();
    if (!cardSnap.exists) throw StateError('card_missing');
    final card = CreditCard.fromSnapshot(cardSnap);

    final expensesSnap = await _db
        .collection('households')
        .doc(hid)
        .collection('expenses')
        .where('cardId', isEqualTo: cardId)
        .get();
    final installmentsSnap = await _installments(hid, cardId).get();
    final installments = {
      for (final d in installmentsSnap.docs)
        d.id: Installment.fromSnapshot(d, cardId),
    };

    var plainTotal = 0;
    final plans = <CicilanPlanState>[];
    for (final d in expensesSnap.docs) {
      final exp = Expense.fromSnapshot(d);
      final planId = exp.installmentPlanId;
      if (planId != null) {
        // Cicilan. Orphaned plans (no installment doc) contribute nothing —
        // same direction as delete(): they're gone.
        final plan = installments[planId];
        if (plan == null) continue;
        plans.add((
          monthsTotal: plan.monthsTotal,
          monthsPaid: plan.monthsPaid,
          monthly: plan.monthly,
          startedAt: plan.startedAt,
        ));
      } else {
        plainTotal += exp.amount;
      }
    }
    final totals = cardDebtTotals(
      plainTotal: plainTotal,
      plainPaid: card.plainPaid,
      plans: plans,
      today: now,
      billingDay: card.billingDay,
    );
    await cardRef.update({
      'used': totals.used,
      'outstanding': totals.outstanding,
    });
    return totals.used;
  }

  /// Advances one month on a single installment: bumps `monthsPaid` and
  /// debits `inst.monthly` from `sourceAccountId`. Card `used` is reconciled
  /// by [recalcUsed] after the tx.
  Future<void> incrementInstallment({
    required String hid,
    required String cardId,
    required String installmentId,
    required String sourceAccountId,
  }) async {
    final instRef = _installments(hid, cardId).doc(installmentId);
    final cardRef = _cards(hid).doc(cardId);
    final householdRef = _db.collection('households').doc(hid);
    final didPay = await _db.runTransaction<bool>((tx) async {
      final instSnap = await tx.get(instRef);
      if (!instSnap.exists) throw StateError('installment_missing');
      final inst = Installment.fromSnapshot(instSnap, cardId);
      if (inst.isComplete) return false;
      final cardSnap = await tx.get(cardRef);
      if (!cardSnap.exists) throw StateError('card_missing');
      // Card snapshot is read to validate existence (atomic with the
      // monthsPaid bump). The actual `used` reconciliation happens via the
      // post-tx recalcUsed call below.
      final hSnap = await tx.get(householdRef);
      if (!hSnap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(hSnap);
      _debitAccountTx(
        tx: tx,
        householdRef: householdRef,
        household: household,
        sourceAccountId: sourceAccountId,
        amount: inst.monthly,
      );
      tx.update(instRef, {'monthsPaid': inst.monthsPaid + 1});
      return true;
    });
    if (didPay) await recalcUsed(hid: hid, cardId: cardId);
  }

  /// Debits `amount` from the cash- or savings-account matching
  /// `sourceAccountId` and writes the updated array back via [tx]. Throws
  /// `account_missing` or `insufficient`.
  void _debitAccountTx({
    required Transaction tx,
    required DocumentReference<Map<String, dynamic>> householdRef,
    required Household household,
    required String sourceAccountId,
    required int amount,
  }) {
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
    if (source.value < amount) throw StateError('insufficient');
    final updated = list
        .map((a) => a.id == sourceAccountId
            ? a.copyWith(value: a.value - amount)
            : a)
        .toList();
    final field =
        kind == AccountKind.cash ? 'cashAccounts' : 'savingsAccounts';
    tx.update(householdRef, {
      field: updated.map((a) => a.toMap()).toList(),
    });
  }
}

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(ref.watch(firestoreProvider));
});
