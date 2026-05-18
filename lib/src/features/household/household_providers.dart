import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../accounts/household_balances.dart';
import 'household.dart';
import 'household_repository.dart';

/// Stream of the current user's `users/{uid}` doc. Null when signed out or
/// when the doc doesn't exist yet (first sign-up).
final currentUserDocProvider =
    StreamProvider<Map<String, dynamic>?>((ref) async* {
  final auth = ref.watch(authStateProvider).value;
  if (auth == null) {
    yield null;
    return;
  }
  final db = ref.watch(firestoreProvider);
  yield* db
      .collection('users')
      .doc(auth.uid)
      .snapshots()
      .map((s) => s.data());
});

/// The user's current household ID, or null if they haven't joined one.
final currentHouseholdIdProvider = Provider<String?>((ref) {
  final doc = ref.watch(currentUserDocProvider).value;
  final hid = doc?['householdId'] as String?;
  return (hid != null && hid.isNotEmpty) ? hid : null;
});

/// Stream of the root household doc only — internal use. Most callers should
/// use [currentHouseholdProvider] which merges balances (SEC-004).
final _currentHouseholdRootProvider = StreamProvider<Household?>((ref) {
  final hid = ref.watch(currentHouseholdIdProvider);
  if (hid == null) return Stream.value(null);
  return ref.watch(householdRepositoryProvider).watch(hid);
});

/// Active household for the signed-in user, with balances merged in from the
/// `private/balances` doc when the caller has `full` access. For `limited`
/// tier members, [Household.cashAccounts] / [Household.savingsAccounts] stay
/// empty (Firestore denies the balances read — SEC-004 privacy promise).
final currentHouseholdProvider = Provider<AsyncValue<Household?>>((ref) {
  final rootAsync = ref.watch(_currentHouseholdRootProvider);
  final balancesAsync = ref.watch(balancesProvider);
  return rootAsync.when(
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
    data: (household) {
      if (household == null) return const AsyncValue.data(null);
      final balances = balancesAsync.value;
      if (balances == null) return AsyncValue.data(household);
      return AsyncValue.data(
        household.withBalances(
          cashAccounts: balances.cashAccounts,
          savingsAccounts: balances.savingsAccounts,
        ),
      );
    },
  );
});

/// Detects the "I was removed from the household" case (creator called
/// `removeMember`). When the household is loaded but the current user is no
/// longer in `members[]`, clear `users/{uid}.householdId` so the router can
/// bounce the user back to onboarding.
///
/// Keep this as a side-effect provider; mount it from `HomeScreen` once.
final orphanedMembershipCleanupProvider = Provider<void>((ref) {
  final user = ref.watch(authStateProvider).value;
  final household = ref.watch(currentHouseholdProvider).value;
  if (user == null || household == null) return;
  if (household.memberOf(user.uid) != null) return;
  // ignore: discarded_futures
  ref.watch(firestoreProvider).collection('users').doc(user.uid).set(
        {'householdId': FieldValue.delete()},
        SetOptions(merge: true),
      );
});

/// The signed-in user's current access level inside their household.
/// Defaults to `full` when the household isn't loaded yet (UI usually
/// guards on `currentHouseholdProvider` first; this just avoids null
/// checks in chip rendering).
final myAccessLevelProvider = Provider<AccessLevel>((ref) {
  final user = ref.watch(authStateProvider).value;
  final household = ref.watch(currentHouseholdProvider).value;
  if (user == null || household == null) return AccessLevel.full;
  return household.memberOf(user.uid)?.accessLevel ?? AccessLevel.full;
});

/// True when the current user can record transactions (full + limited).
final canRecordTxnProvider = Provider<bool>((ref) {
  final lvl = ref.watch(myAccessLevelProvider);
  return lvl == AccessLevel.full || lvl == AccessLevel.limited;
});

/// True when the current user can write everything (settings, cards, goals).
final canWriteAllProvider = Provider<bool>((ref) {
  return ref.watch(myAccessLevelProvider) == AccessLevel.full;
});

/// Stream of the household's private balances doc. Returns `null` when the
/// caller is not a `full`-tier member (Firestore denies the read) — UI must
/// branch on null and hide balance amounts. SEC-004.
///
/// Reads access level from the root provider directly to avoid a cycle with
/// [currentHouseholdProvider] (which merges balances back in).
final balancesProvider = StreamProvider<HouseholdBalances?>((ref) {
  final hid = ref.watch(currentHouseholdIdProvider);
  final user = ref.watch(authStateProvider).value;
  final root = ref.watch(_currentHouseholdRootProvider).value;
  if (hid == null || user == null || root == null) return Stream.value(null);
  final level = root.memberOf(user.uid)?.accessLevel ?? AccessLevel.full;
  if (level != AccessLevel.full) return Stream.value(null);
  final db = ref.watch(firestoreProvider);
  return HouseholdBalances.ref(db, hid).snapshots().map(
        (snap) => snap.exists
            ? HouseholdBalances.fromSnapshot(snap)
            : HouseholdBalances.empty,
      );
});

/// Convenience: the current Firebase user (throws if absent — use in screens
/// where auth is guaranteed by the router).
User requireUser(WidgetRef ref) {
  final user = ref.read(authStateProvider).value;
  if (user == null) throw StateError('no_signed_in_user');
  return user;
}
