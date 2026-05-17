/// Materialises monthly auto-debit transfers for goals flagged with
/// `autoDebit: true`. Patterned after `lib/src/core/recurring_runner.dart`:
/// runs once per app session per household (gated by [_lastRunPerHousehold])
/// and is idempotent across devices via the `lastAutoDebitMonth` field on
/// each goal doc.
///
/// For each eligible goal:
///   1. Read its `lastAutoDebitMonth` (`YYYY-MM`).
///   2. Walk months from `last + 1` up to and including the current month.
///   3. For each missed month: in a transaction, decrement the source
///      account by `monthlyContrib`, increment `goal.current` (clamped at
///      `target`), and update `lastAutoDebitMonth`.
///
/// Accepts up-to-1-month lag if nobody opens the app — same trade-off the
/// existing recurring runner makes.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../accounts/account.dart';
import '../household/household.dart';
import 'goal.dart';

final _lastRunPerHousehold = <String, DateTime>{};

class AutoDebitRunner {
  AutoDebitRunner(this._db);
  final FirebaseFirestore _db;

  /// Materialises any missed auto-debit transfers up to [now]. Returns the
  /// number of transfers created.
  Future<int> run({
    required String householdId,
    DateTime? now,
  }) async {
    final n = now ?? DateTime.now();
    final last = _lastRunPerHousehold[householdId];
    // Guard against repeated runs within an hour (e.g. hot reload).
    if (last != null && n.difference(last).inMinutes < 60) {
      return 0;
    }
    _lastRunPerHousehold[householdId] = n;

    final hRef = _db.collection('households').doc(householdId);
    final goalsCol = hRef.collection('goals');

    final snap = await goalsCol.where('autoDebit', isEqualTo: true).get();
    if (snap.docs.isEmpty) return 0;

    var created = 0;
    for (final doc in snap.docs) {
      final goal = Goal.fromSnapshot(doc);
      if (goal.monthlyContrib <= 0 || goal.sourceAccountId == null) continue;
      if (goal.isComplete) continue;

      final months = monthsToMaterialise(
        lastSeen: goal.lastAutoDebitMonth,
        now: n,
      );
      for (final ym in months) {
        final ok = await _materialise(
          householdRef: hRef,
          goalRef: goalsCol.doc(goal.id),
          goal: goal,
          yyyymm: ym,
        );
        if (ok) {
          created++;
        } else {
          // Source missing or insufficient — stop walking this goal so the
          // next month doesn't double-debit if ops manually fix it later.
          break;
        }
      }
    }
    return created;
  }

  Future<bool> _materialise({
    required DocumentReference<Map<String, dynamic>> householdRef,
    required DocumentReference<Map<String, dynamic>> goalRef,
    required Goal goal,
    required String yyyymm,
  }) async {
    try {
      await _db.runTransaction((tx) async {
        final hSnap = await tx.get(householdRef);
        final gSnap = await tx.get(goalRef);
        if (!hSnap.exists || !gSnap.exists) {
          throw StateError('missing');
        }
        final household = Household.fromSnapshot(hSnap);
        final fresh = Goal.fromSnapshot(gSnap);
        if (fresh.lastAutoDebitMonth == yyyymm) return; // raced; skip
        final source = household.cashAccounts.firstWhere(
          (a) => a.id == goal.sourceAccountId,
          orElse: () => Account(
            id: '',
            kind: AccountKind.cash,
            label: '',
            hint: null,
            value: 0,
            sortOrder: 0,
          ),
        );
        if (source.id.isEmpty || source.value < goal.monthlyContrib) {
          throw StateError('insufficient');
        }
        final updatedCash = household.cashAccounts
            .map((a) => a.id == source.id
                ? a.copyWith(value: a.value - goal.monthlyContrib)
                : a)
            .toList();
        final next = (fresh.current + goal.monthlyContrib)
            .clamp(0, fresh.target);
        tx.update(householdRef, {
          'cashAccounts': updatedCash.map((a) => a.toMap()).toList(),
        });
        tx.update(goalRef, {
          'current': next,
          'lastAutoDebitMonth': yyyymm,
        });
      });
      return true;
    } on StateError {
      return false;
    }
  }
}

/// Returns ordered `YYYY-MM` strings from the month after [lastSeen] (or
/// the current month if [lastSeen] is null) up to and including [now]'s
/// month. If [lastSeen] is the current month, returns an empty list.
List<String> monthsToMaterialise({
  required String? lastSeen,
  required DateTime now,
}) {
  final out = <String>[];
  final currentYm = _ym(now);
  if (lastSeen == null) {
    out.add(currentYm);
    return out;
  }
  if (lastSeen == currentYm) return out;
  final parts = lastSeen.split('-');
  if (parts.length != 2) {
    out.add(currentYm);
    return out;
  }
  var year = int.tryParse(parts[0]) ?? now.year;
  var month = int.tryParse(parts[1]) ?? now.month;
  while (true) {
    month++;
    if (month > 12) {
      month = 1;
      year++;
    }
    final ym = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    out.add(ym);
    if (year == now.year && month == now.month) break;
    if (out.length > 12) break; // safety: cap at 1 year of catch-up
  }
  return out;
}

String _ym(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

final autoDebitRunnerProvider = Provider<AutoDebitRunner>((ref) {
  return AutoDebitRunner(ref.watch(firestoreProvider));
});

/// Test-only: clear the per-session gate.
void resetAutoDebitRunnerGateForTests() => _lastRunPerHousehold.clear();
