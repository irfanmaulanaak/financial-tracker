import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
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

/// Stream of the active household for the signed-in user.
final currentHouseholdProvider = StreamProvider<Household?>((ref) {
  final hid = ref.watch(currentHouseholdIdProvider);
  if (hid == null) return Stream.value(null);
  return ref.watch(householdRepositoryProvider).watch(hid);
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
