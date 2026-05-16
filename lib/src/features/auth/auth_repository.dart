import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/providers.dart';

/// Firebase Hosting action URL for the project — used as the landing page
/// when the email link is clicked. Universal/App Links aren't configured
/// (internal app, 2-5 users), so users paste the link back into the app.
const String _emailLinkActionUrl =
    'https://financial-tracker-4791d.firebaseapp.com/__/auth/action';

class AuthRepository {
  AuthRepository(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    await _ensureUserDoc(
      uid: cred.user!.uid,
      email: email,
      displayName: displayName,
      photoURL: null,
    );
    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Google sign-in (and sign-up — Firebase auto-creates the auth user on
  /// first credential exchange). Also upserts the `users/{uid}` profile doc
  /// so the router can detect "no household → onboarding" cleanly.
  ///
  /// Throws `FirebaseAuthException` for credential issues, or
  /// `GoogleSignInException(code: canceled)` if the user dismisses the sheet.
  /// Per AGENTS.md (fail LOUD): we do NOT swallow either.
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn.instance.authenticate();
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google did not return an ID token.',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final result = await _auth.signInWithCredential(credential);
    final user = result.user!;
    await _ensureUserDoc(
      uid: user.uid,
      email: user.email ?? googleUser.email,
      displayName: user.displayName ?? googleUser.displayName ?? '',
      photoURL: user.photoURL,
    );
    return result;
  }

  /// Idempotent: only writes when the user doc is missing, so subsequent
  /// Google sign-ins don't clobber an existing `householdId`.
  Future<void> _ensureUserDoc({
    required String uid,
    required String email,
    required String displayName,
    required String? photoURL,
  }) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'householdId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Step 1 of passwordless sign-in: emails a magic link to the user.
  /// Caller must remember the email for [signInWithEmailLink].
  Future<void> sendEmailLink({required String email}) async {
    final actionCodeSettings = ActionCodeSettings(
      url: _emailLinkActionUrl,
      handleCodeInApp: true,
      iOSBundleId: 'com.irfanmaulanaakbar.financialTracker',
      androidPackageName: 'com.irfanmaulanaakbar.financial_tracker',
      androidInstallApp: false,
    );
    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  /// Step 2 of passwordless sign-in. `link` is the full URL from the email.
  /// Firebase auto-creates the auth user if it doesn't exist. We upsert the
  /// `users/{uid}` profile doc with `displayName` derived from the email
  /// local-part as a sensible default; user can rename later.
  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String link,
  }) async {
    if (!_auth.isSignInWithEmailLink(link)) {
      throw FirebaseAuthException(
        code: 'invalid-action-code',
        message: 'Link tidak valid atau sudah kedaluwarsa.',
      );
    }
    final result = await _auth.signInWithEmailLink(
      email: email,
      emailLink: link,
    );
    final user = result.user!;
    final fallbackName =
        (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!
            : email.split('@').first;
    await _ensureUserDoc(
      uid: user.uid,
      email: user.email ?? email,
      displayName: fallbackName,
      photoURL: user.photoURL,
    );
    return result;
  }

  /// Pure helper — true if `link` looks like a Firebase sign-in link.
  /// Exposed so the UI can sanity-check the pasted URL before submitting.
  bool isSignInWithEmailLink(String link) => _auth.isSignInWithEmailLink(link);

  Future<void> signOut() async {
    // Best-effort Google sign-out; safe to ignore failures (user might not be
    // signed in via Google).
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});
