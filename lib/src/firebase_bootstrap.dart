import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

/// Web OAuth client ID from the Firebase project. Public value (mirrors what
/// `google-services.json` ships to every install), so safe to hardcode. Used
/// as `serverClientId` on Android/iOS so the Google ID token's audience
/// matches what `signInWithCredential` expects on the Firebase Auth backend.
/// Override at build time with `--dart-define=FT_GOOGLE_WEB_CLIENT_ID=...`
/// if you ever rotate the OAuth client.
const _defaultGoogleWebClientId =
    '361266947064-v28oc1mqmucehibejqqq1vngp3nk5g0k.apps.googleusercontent.com';
const _googleWebClientIdOverride =
    String.fromEnvironment('FT_GOOGLE_WEB_CLIENT_ID');

/// reCAPTCHA v3 site key for Firebase App Check on web. Pass at build time via
/// `--dart-define=FT_RECAPTCHA_V3_SITE_KEY=...`. Empty by default so debug web
/// builds fall back to the App Check debug provider.
const _recaptchaV3SiteKey =
    String.fromEnvironment('FT_RECAPTCHA_V3_SITE_KEY');

/// Initialises Firebase. If `FT_USE_EMULATOR=1` is set (or `useEmulator` is
/// passed manually), wires both Auth + Firestore to the local emulator.
Future<void> bootstrapFirebase({bool? useEmulator}) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final shouldUseEmulator =
      useEmulator ?? const String.fromEnvironment('FT_USE_EMULATOR') == '1';

  // App Check must activate BEFORE any Firestore/Auth call. In debug / emulator
  // builds we use the debug provider so dev machines without a real attestation
  // signal can still talk to Firebase. Production builds use Play Integrity
  // (Android), App Attest (iOS), and reCAPTCHA v3 (web). Enable enforcement in
  // the Firebase console only after this is rolled out to all users.
  //
  // Failures here MUST NOT brick startup — if the reCAPTCHA script is blocked
  // (CSP, network) or the site key is wrong, the app should still boot. The
  // worst case once enforcement is on is that Firestore/Auth calls fail
  // visibly with a permission error, which the UI can surface.
  final useDebugProvider = kDebugMode || shouldUseEmulator;
  final webKey = _recaptchaV3SiteKey.trim();
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: useDebugProvider
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: useDebugProvider
          ? const AppleDebugProvider()
          : const AppleAppAttestProvider(),
      providerWeb: useDebugProvider || webKey.isEmpty
          ? ReCaptchaV3Provider('debug')
          : ReCaptchaV3Provider(webKey),
    );
  } catch (e, st) {
    debugPrint('App Check activation failed (continuing): $e\n$st');
  }

  if (!kIsWeb) {
    final serverClientId = _googleWebClientIdOverride.trim().isEmpty
        ? _defaultGoogleWebClientId
        : _googleWebClientIdOverride.trim();
    try {
      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    } catch (e, st) {
      debugPrint('Google Sign-In init failed: $e\n$st');
    }
  }

  if (!shouldUseEmulator) return;

  final host = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
}
