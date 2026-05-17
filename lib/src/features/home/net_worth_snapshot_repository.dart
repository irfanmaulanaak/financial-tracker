import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/net_worth.dart';
import '../../core/providers.dart';
import '../household/household_providers.dart';
import 'net_worth_snapshot.dart';

class NetWorthSnapshotRepository {
  NetWorthSnapshotRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String hid) => _db
      .collection('households')
      .doc(hid)
      .collection('netWorthSnapshots');

  /// Idempotent per day: writes today's snapshot only when the doc is
  /// missing OR when the rolled-up `total` has changed since the last
  /// recorded value. No-op otherwise.
  ///
  /// Doc id is `YYYY-MM-DD` (local). Repeated calls within the same day
  /// won't proliferate rows or thrash Firestore quota.
  Future<void> recordToday({
    required String householdId,
    required NetWorth nw,
    required String capturedBy,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final midnight = localMidnight(ts);
    final ref = _col(householdId).doc(snapshotDocId(midnight));
    final snap = NetWorthSnapshot(
      date: midnight,
      cash: nw.cash,
      savings: nw.savings,
      investments: nw.investments,
      debt: nw.debt,
      total: nw.total,
      capturedBy: capturedBy,
    );
    await _db.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) {
        final prev = NetWorthSnapshot.fromSnapshot(existing);
        if (prev.total == snap.total &&
            prev.cash == snap.cash &&
            prev.savings == snap.savings &&
            prev.investments == snap.investments &&
            prev.debt == snap.debt) {
          return;
        }
      }
      tx.set(ref, snap.toMap());
    });
  }

  /// Most recent [days] snapshots, oldest first (chart-friendly order).
  Stream<List<NetWorthSnapshot>> recent({
    required String householdId,
    int days = 14,
  }) {
    return _col(householdId)
        .orderBy('date', descending: true)
        .limit(days)
        .snapshots()
        .map((s) {
      final out = s.docs.map(NetWorthSnapshot.fromSnapshot).toList();
      out.sort((a, b) => a.date.compareTo(b.date));
      return out;
    });
  }
}

final netWorthSnapshotRepositoryProvider =
    Provider<NetWorthSnapshotRepository>((ref) {
  return NetWorthSnapshotRepository(ref.watch(firestoreProvider));
});

/// Last [days] daily totals for the current household, oldest-first.
/// Returns an empty list while the household isn't loaded.
final netWorthHistoryProvider =
    StreamProvider.family<List<NetWorthSnapshot>, int>((ref, days) {
  final hid = ref.watch(currentHouseholdIdProvider);
  if (hid == null) return Stream.value(const []);
  return ref
      .watch(netWorthSnapshotRepositoryProvider)
      .recent(householdId: hid, days: days);
});
