import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'goal.dart';

class GoalRepository {
  GoalRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String hid) =>
      _db.collection('households').doc(hid).collection('goals');

  Stream<List<Goal>> watchAll(String hid) {
    return _col(hid).snapshots().map(
          (s) => s.docs.map(Goal.fromSnapshot).toList()
            ..sort((a, b) {
              // Personal goals show after shared; alphabetical within group.
              if (a.scope != b.scope) {
                return a.scope == GoalScope.shared ? -1 : 1;
              }
              return a.label.compareTo(b.label);
            }),
        );
  }

  Stream<Goal?> watchOne({required String hid, required String goalId}) {
    return _col(hid).doc(goalId).snapshots().map(
          (s) => s.exists ? Goal.fromSnapshot(s) : null,
        );
  }

  Future<String> add({
    required String hid,
    required String label,
    required int target,
    int current = 0,
    DateTime? dueDate,
    int monthlyContrib = 0,
    String icon = 'savings',
    String color = '#10B981',
    required GoalScope scope,
    String? ownerId,
    bool autoDebit = false,
    int autoDebitDay = 1,
    String? sourceAccountId,
    String? presetId,
    DateTime? now,
  }) async {
    final ref = _col(hid).doc();
    final goal = Goal(
      id: ref.id,
      label: label,
      target: target,
      current: current,
      dueDate: dueDate,
      monthlyContrib: monthlyContrib,
      icon: icon,
      color: color,
      scope: scope,
      ownerId: scope == GoalScope.personal ? ownerId : null,
      createdAt: now ?? DateTime.now(),
      autoDebit: autoDebit && sourceAccountId != null && monthlyContrib > 0,
      autoDebitDay: autoDebitDay.clamp(1, 28),
      sourceAccountId: sourceAccountId,
      presetId: presetId,
    );
    await ref.set(goal.toMap());
    return ref.id;
  }

  Future<void> contribute({
    required String hid,
    required String goalId,
    required int amount,
  }) async {
    final ref = _col(hid).doc(goalId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('goal_missing');
      final goal = Goal.fromSnapshot(snap);
      final next = (goal.current + amount).clamp(0, goal.target);
      tx.update(ref, {'current': next});
    });
  }

  Future<void> updateGoal({
    required String hid,
    required String goalId,
    String? label,
    int? target,
    DateTime? dueDate,
    int? monthlyContrib,
    String? icon,
    String? color,
    bool? autoDebit,
    int? autoDebitDay,
    String? sourceAccountId,
  }) async {
    await _col(hid).doc(goalId).update({
      'label': ?label,
      'target': ?target,
      'dueDate': ?dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'monthlyContrib': ?monthlyContrib,
      'icon': ?icon,
      'color': ?color,
      'autoDebit': ?autoDebit,
      'autoDebitDay': ?autoDebitDay,
      'sourceAccountId': ?sourceAccountId,
    });
  }

  /// Marks an auto-debit run done for [yyyymm] (format `YYYY-MM`). Used by
  /// [AutoDebitRunner] in a transaction together with the contribution.
  Future<void> markAutoDebitDone({
    required String hid,
    required String goalId,
    required String yyyymm,
  }) async {
    await _col(hid).doc(goalId).update({'lastAutoDebitMonth': yyyymm});
  }

  Future<void> delete({required String hid, required String goalId}) async {
    await _col(hid).doc(goalId).delete();
  }
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(firestoreProvider));
});
