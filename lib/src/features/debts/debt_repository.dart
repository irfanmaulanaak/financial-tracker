import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/debt_math.dart';
import '../../core/providers.dart';
import '../household/household_providers.dart';
import 'debt.dart';

class DebtRepository {
  DebtRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String hid) =>
      _db.collection('households').doc(hid).collection('debts');

  Stream<List<Debt>> watchAll(String householdId) {
    return _col(householdId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Debt.fromSnapshot).toList());
  }

  Future<String> add({
    required String householdId,
    required DebtType type,
    required String counterparty,
    required int amount,
    required String createdBy,
    String? note,
    DateTime? dueDate,
  }) async {
    final ref = _col(householdId).doc();
    await ref.set(Debt(
      id: ref.id,
      type: type,
      counterparty: counterparty,
      amount: amount,
      paid: 0,
      note: note,
      dueDate: dueDate,
      settled: false,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    ).toMap());
    return ref.id;
  }

  /// Catat pembayaran/cicilan. Transactional supaya dua anggota yang
  /// mencatat bersamaan tidak saling menimpa.
  Future<void> addPayment({
    required String householdId,
    required String debtId,
    required int payment,
  }) {
    final ref = _col(householdId).doc(debtId);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('debt_missing');
      final debt = Debt.fromSnapshot(snap);
      final r = applyDebtPayment(
        amount: debt.amount,
        paid: debt.paid,
        payment: payment,
      );
      tx.update(ref, {'paid': r.paid, 'settled': r.settled});
    });
  }

  Future<void> delete({
    required String householdId,
    required String debtId,
  }) {
    return _col(householdId).doc(debtId).delete();
  }
}

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepository(ref.watch(firestoreProvider));
});

/// Semua catatan utang/piutang rumah tangga (terbaru dulu).
final debtsProvider = StreamProvider<List<Debt>>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);
  return ref.watch(debtRepositoryProvider).watchAll(household.id);
});
