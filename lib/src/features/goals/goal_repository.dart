import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'contribution.dart';
import 'goal.dart';

class GoalRepository {
  GoalRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String hid) =>
      _db.collection('households').doc(hid).collection('goals');
  CollectionReference<Map<String, dynamic>> _contribs(
          String hid, String goalId) =>
      _col(hid).doc(goalId).collection('contributions');

  Stream<List<GoalContribution>> watchContributions({
    required String hid,
    required String goalId,
    int limit = 60,
  }) {
    return _contribs(hid, goalId)
        .orderBy('at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(GoalContribution.fromSnapshot).toList());
  }

  Stream<List<Goal>> watchAll(String hid) {
    return _col(hid).snapshots().map(
          (s) => s.docs.map(Goal.fromSnapshot).toList()
            ..sort((a, b) {
              final ai = a.sortIndex ?? a.createdAt.millisecondsSinceEpoch;
              final bi = b.sortIndex ?? b.createdAt.millisecondsSinceEpoch;
              return ai.compareTo(bi);
            }),
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
    String? presetId,
    String? fundingType,
    String? fundingId,
    DateTime? now,
  }) async {
    final ref = _col(hid).doc();
    final createdAt = now ?? DateTime.now();
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
      createdAt: createdAt,
      presetId: presetId,
      fundingType: fundingType,
      fundingId: fundingId,
      // Newest goals append to the bottom by default; user can drag to
      // reorder. Epoch ms is large enough to stay below legacy goals'
      // `createdAt`-based fallback only when their createdAt is also recent.
      sortIndex: createdAt.millisecondsSinceEpoch,
    );
    await ref.set(goal.toMap());
    return ref.id;
  }

  /// Rewrites `sortIndex` on every goal in [orderedIds] so they sort in the
  /// given order. Uses a stride of 1000 to leave room for future inserts.
  Future<void> reorderGoals({
    required String hid,
    required List<String> orderedIds,
  }) async {
    final batch = _db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(_col(hid).doc(orderedIds[i]), {'sortIndex': (i + 1) * 1000});
    }
    await batch.commit();
  }

  /// Records a deposit toward [goalId]: bumps `goal.current` (clamped at
  /// `target`) AND writes a `contributions/{cid}` doc in the same
  /// transaction. The contribution doc is the audit trail behind the
  /// goal-detail bar chart.
  Future<void> contribute({
    required String hid,
    required String goalId,
    required int amount,
    required String byUid,
    GoalContributionSource source = GoalContributionSource.manual,
    DateTime? at,
  }) async {
    final goalRef = _col(hid).doc(goalId);
    final contribRef = _contribs(hid, goalId).doc();
    final ts = at ?? DateTime.now();
    await _db.runTransaction((tx) async {
      final snap = await tx.get(goalRef);
      if (!snap.exists) throw StateError('goal_missing');
      final goal = Goal.fromSnapshot(snap);
      final next = (goal.current + amount).clamp(0, goal.target);
      tx.update(goalRef, {'current': next});
      tx.set(contribRef, GoalContribution(
        id: contribRef.id,
        amount: amount,
        at: ts,
        byUid: byUid,
        source: source,
      ).toMap());
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
  }) async {
    await _col(hid).doc(goalId).update({
      'label': ?label,
      'target': ?target,
      'dueDate': ?dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'monthlyContrib': ?monthlyContrib,
      'icon': ?icon,
      'color': ?color,
    });
  }

  /// Set/ganti/putus sumber dana goal. [type]+[id] null = kembali manual
  /// (field dihapus; `current` lama dipakai lagi sebagai nilai manual).
  Future<void> setFunding({
    required String hid,
    required String goalId,
    String? type,
    String? id,
  }) async {
    final linked = type != null && id != null;
    await _col(hid).doc(goalId).update({
      'fundingType': linked ? type : FieldValue.delete(),
      'fundingId': linked ? id : FieldValue.delete(),
    });
  }

  Future<void> delete({required String hid, required String goalId}) async {
    await _col(hid).doc(goalId).delete();
  }
}

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(firestoreProvider));
});

/// Most recent goal contributions (manual + auto-debit), newest first.
/// Powers the goal-detail "Setoran 8 Bulan Terakhir" bar chart.
final goalContributionsProvider = StreamProvider.family<List<GoalContribution>,
    ({String hid, String goalId})>((ref, p) {
  return ref.watch(goalRepositoryProvider).watchContributions(
        hid: p.hid,
        goalId: p.goalId,
      );
});
