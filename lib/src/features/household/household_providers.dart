import 'package:firebase_auth/firebase_auth.dart';
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

/// Convenience: the current Firebase user (throws if absent — use in screens
/// where auth is guaranteed by the router).
User requireUser(WidgetRef ref) {
  final user = ref.read(authStateProvider).value;
  if (user == null) throw StateError('no_signed_in_user');
  return user;
}
