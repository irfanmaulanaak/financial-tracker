import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'investment.dart';

class InvestmentsRepository {
  InvestmentsRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String hid) =>
      _db.collection('households').doc(hid).collection('investments');

  Stream<List<Investment>> watchAll(String hid) {
    return _col(hid).snapshots().map((s) {
      final list = s.docs.map(Investment.fromSnapshot).toList()
        ..sort((a, b) => b.currentValue.compareTo(a.currentValue));
      return list;
    });
  }

  Future<String> add({
    required String hid,
    required String label,
    required InvestmentType type,
    required int currentValue,
    required int costBasis,
    DateTime? now,
  }) async {
    final ref = _col(hid).doc();
    await ref.set(Investment(
      id: ref.id,
      label: label,
      type: type,
      currentValue: currentValue,
      costBasis: costBasis,
      updatedAt: now ?? DateTime.now(),
    ).toMap());
    return ref.id;
  }

  Future<void> updateValue({
    required String hid,
    required String id,
    required int currentValue,
    DateTime? now,
  }) async {
    await _col(hid).doc(id).update({
      'currentValue': currentValue,
      'updatedAt': Timestamp.fromDate(now ?? DateTime.now()),
    });
  }

  Future<void> delete({required String hid, required String id}) async {
    await _col(hid).doc(id).delete();
  }
}

final investmentsRepositoryProvider = Provider<InvestmentsRepository>((ref) {
  return InvestmentsRepository(ref.watch(firestoreProvider));
});

final investmentsProvider = StreamProvider.family<List<Investment>, String>((
  ref,
  hid,
) {
  return ref.watch(investmentsRepositoryProvider).watchAll(hid);
});
