import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../accounts/account.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import 'obligation.dart';

class ObligationRepository {
  ObligationRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _householdDoc(String hid) =>
      _db.collection('households').doc(hid);
  CollectionReference<Map<String, dynamic>> _col(String hid) =>
      _householdDoc(hid).collection('obligations');

  Stream<List<Obligation>> watchAll(String hid) {
    return _col(hid)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Obligation.fromSnapshot).toList());
  }

  Future<String> add({
    required String hid,
    required String label,
    required int monthly,
    required int monthsTotal,
    required int monthsPaid,
    required int dueDay,
    required String createdBy,
    bool isDebt = true,
    int? outstandingPrincipal,
  }) async {
    final ref = _col(hid).doc();
    await ref.set(Obligation(
      id: ref.id,
      label: label,
      monthly: monthly,
      monthsTotal: monthsTotal,
      monthsPaid: monthsPaid,
      dueDay: dueDay,
      isDebt: isDebt,
      outstandingPrincipal: outstandingPrincipal,
      startedAt: DateTime.now(),
      createdBy: createdBy,
    ).toMap());
    return ref.id;
  }

  Future<void> update({
    required String hid,
    required String obligationId,
    required Map<String, dynamic> fields,
  }) {
    return _col(hid).doc(obligationId).update(fields);
  }

  /// Bayar 1 bulan: monthsPaid +1, saldo rekening −monthly.
  /// [expectedMonthsPaid] menolak dobel bayar dari dua device (transaksi
  /// retry membaca state terbaru, tanpa guard ini 4/12 bisa loncat ke 6/12).
  /// Pokok TIDAK dikurangi otomatis — monthly termasuk bunga; user
  /// memperbarui sisa pokok dari info leasing/bank via edit.
  Future<void> payMonth({
    required String hid,
    required String obligationId,
    required String accountId,
    required int expectedMonthsPaid,
  }) {
    final oRef = _col(hid).doc(obligationId);
    final hRef = _householdDoc(hid);
    return _db.runTransaction((tx) async {
      final oSnap = await tx.get(oRef);
      if (!oSnap.exists) throw StateError('obligation_missing');
      final o = Obligation.fromSnapshot(oSnap);
      if (o.isComplete) return;
      if (o.monthsPaid != expectedMonthsPaid) {
        throw StateError('already_paid');
      }

      final hSnap = await tx.get(hRef);
      if (!hSnap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(hSnap);
      final inCash =
          household.cashAccounts.where((a) => a.id == accountId).toList();
      final inSavings =
          household.savingsAccounts.where((a) => a.id == accountId).toList();
      if (inCash.isEmpty && inSavings.isEmpty) {
        throw StateError('account_missing');
      }
      final kind = inCash.isNotEmpty ? AccountKind.cash : AccountKind.savings;
      final list = kind == AccountKind.cash
          ? household.cashAccounts
          : household.savingsAccounts;
      final account = (kind == AccountKind.cash ? inCash : inSavings).first;
      if (account.value < o.monthly) throw StateError('insufficient_balance');
      final updated = list
          .map((a) =>
              a.id == accountId ? a.copyWith(value: a.value - o.monthly) : a)
          .toList();
      final field =
          kind == AccountKind.cash ? 'cashAccounts' : 'savingsAccounts';

      tx.update(oRef, {
        'monthsPaid': o.monthsPaid + 1,
        'lastPaidAt': Timestamp.now(),
      });
      tx.update(hRef, {field: updated.map((a) => a.toMap()).toList()});
    });
  }

  Future<void> delete({required String hid, required String obligationId}) {
    return _col(hid).doc(obligationId).delete();
  }
}

final obligationRepositoryProvider = Provider<ObligationRepository>((ref) {
  return ObligationRepository(ref.watch(firestoreProvider));
});

final obligationsProvider = StreamProvider<List<Obligation>>((ref) {
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(const []);
  return ref.watch(obligationRepositoryProvider).watchAll(household.id);
});

/// Total cicilan tetap bulanan yang masih berjalan.
final activeObligationsMonthlyProvider = Provider<int>((ref) {
  final list = ref.watch(obligationsProvider).value ?? const [];
  return list
      .where((o) => !o.isComplete)
      .fold<int>(0, (a, o) => a + o.monthly);
});
