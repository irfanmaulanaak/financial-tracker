import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cicilan.dart';
import '../../core/providers.dart';
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
      dueDay: dueDay,
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
    double? apr,
    String? accent,
    double? minPaymentPct,
  }) async {
    await _cards(hid).doc(cardId).update({
      'label': ?label,
      'last4': ?last4,
      'limit': ?limit,
      'dueDay': ?dueDay,
      'apr': ?apr,
      'accent': ?accent,
      'minPaymentPct': ?minPaymentPct,
    });
  }

  Future<void> deleteCard({required String hid, required String cardId}) async {
    await _cards(hid).doc(cardId).delete();
  }

  /// Atomically: (a) adjusts card.used by +delta (clamped at 0).
  /// Used by the expense flow when a CC payment is recorded.
  Future<void> applyUsageDelta({
    required String hid,
    required String cardId,
    required int delta,
  }) async {
    final ref = _cards(hid).doc(cardId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('card_missing');
      final card = CreditCard.fromSnapshot(snap);
      final next = (card.used + delta).clamp(0, 1 << 31);
      tx.update(ref, {'used': next});
    });
  }

  /// Applies the card's minimum payment: subtracts `minimumPayment(...)` from
  /// `card.used`. Returns the amount applied.
  Future<int> payMinimum({required String hid, required String cardId}) async {
    final ref = _cards(hid).doc(cardId);
    return _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('card_missing');
      final card = CreditCard.fromSnapshot(snap);
      final amount = minimumPayment(
        balance: card.used,
        minPaymentPct: card.minPaymentPct,
      );
      tx.update(ref, {'used': card.used - amount});
      return amount;
    });
  }

  /// Pays the full balance: sets `card.used` to 0. Returns the amount paid.
  Future<int> payFull({required String hid, required String cardId}) async {
    final ref = _cards(hid).doc(cardId);
    return _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('card_missing');
      final card = CreditCard.fromSnapshot(snap);
      tx.update(ref, {'used': 0});
      return card.used;
    });
  }

  /// Increments `monthsPaid` on an installment (manual progression). When the
  /// last month is paid the plan is marked complete (no further actions).
  Future<void> incrementInstallment({
    required String hid,
    required String cardId,
    required String installmentId,
  }) async {
    final ref = _installments(hid, cardId).doc(installmentId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('installment_missing');
      final inst = Installment.fromSnapshot(snap, cardId);
      if (inst.isComplete) return;
      tx.update(ref, {'monthsPaid': inst.monthsPaid + 1});
    });
  }
}

final cardRepositoryProvider = Provider<CardRepository>((ref) {
  return CardRepository(ref.watch(firestoreProvider));
});
