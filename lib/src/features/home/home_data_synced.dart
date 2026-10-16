import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/payday.dart';
import '../expenses/expense_repository.dart';
import '../household/household_providers.dart';
import '../incomes/income_repository.dart';

/// Offline fallback so the home never waits forever.
const _syncFallback = Duration(seconds: 4);

/// Session latch — once the hero data has come from the server it stays synced
/// for the rest of the session, even across household re-emits / tab revisits.
bool _syncedThisSession = false;

/// Emits `false` until every stream in [serverSynced] has delivered at least
/// one `true` (a server, non-cache snapshot), or [fallback] elapses — then
/// emits `true` once and stays there. Pure (no Firestore), so the gating logic
/// can be unit-tested with fake streams and fake time.
Stream<bool> homeSyncedStream(
  List<Stream<bool>> serverSynced, {
  Duration fallback = _syncFallback,
}) {
  final subs = <StreamSubscription<bool>>[];
  final satisfied = <int>{};
  Timer? timer;
  var done = false;
  late StreamController<bool> controller;

  void cleanup() {
    timer?.cancel();
    timer = null;
    for (final s in subs) {
      // ignore: discarded_futures
      s.cancel();
    }
    subs.clear();
  }

  void finish() {
    if (done) return;
    done = true;
    controller.add(true);
    cleanup();
    // ignore: discarded_futures
    controller.close();
  }

  void start() {
    controller.add(false);
    if (serverSynced.isEmpty) {
      finish();
      return;
    }
    timer = Timer(fallback, finish);
    for (var i = 0; i < serverSynced.length; i++) {
      final idx = i;
      subs.add(serverSynced[i].listen(
        (fromServer) {
          if (done || !fromServer) return;
          satisfied.add(idx);
          if (satisfied.length == serverSynced.length) finish();
        },
        onError: (Object _) {},
      ));
    }
  }

  controller = StreamController<bool>(onListen: start, onCancel: cleanup);
  return controller.stream;
}

/// True once every Firestore query behind the hero numbers has delivered a
/// server (non-cache) snapshot — or after a 4s offline fallback. The hero holds
/// its waiting state until then so the entrance doesn't animate over Firestore's
/// cache-first snapshots (which arrive partial, from other listeners).
///
/// Gated queries (same shapes as the data providers, so Firestore shares the
/// listeners and no extra reads happen):
///   1. current-cycle expenses  — drives spent, remaining, perDay, mood.
///   2. previous-cycles expenses — the rollover carry folded into the budget.
///   3. recent incomes (limit 200) — behind stable salary → disposable budget.
final homeDataSyncedProvider = StreamProvider<bool>((ref) {
  if (_syncedThisSession) return Stream.value(true);
  final household = ref.watch(currentHouseholdProvider).value;
  if (household == null) return Stream.value(false);

  final cycle = currentCycle(DateTime.now(), payday: household.payday);
  // Earliest start of the 3 previous cycles — identical range to
  // previousCyclesExpensesProvider(3).
  var earliest = cycle.start;
  for (var i = 0; i < 3; i++) {
    earliest = resolvePayday(earliest.year, earliest.month - 1, household.payday);
  }

  final expenses = ref.watch(expenseRepositoryProvider);
  final incomes = ref.watch(incomeRepositoryProvider);
  return homeSyncedStream([
    expenses.watchRangeServerSynced(
      householdId: household.id,
      startInclusive: cycle.start,
      endExclusive: cycle.endExclusive,
    ),
    expenses.watchRangeServerSynced(
      householdId: household.id,
      startInclusive: earliest,
      endExclusive: cycle.start,
    ),
    incomes.watchRecentServerSynced(hid: household.id, limit: 200),
  ]).map((synced) {
    if (synced) _syncedThisSession = true;
    return synced;
  });
});
