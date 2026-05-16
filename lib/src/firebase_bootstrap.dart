import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Initialises Firebase. If `FT_USE_EMULATOR=1` is set (or `useEmulator` is
/// passed manually), wires both Auth + Firestore to the local emulator.
Future<void> bootstrapFirebase({bool? useEmulator}) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Native google_sign_in v7 requires a one-shot init. Web uses Firebase Auth's
  // popup flow in AuthRepository, so it does not need google_sign_in init.
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

  final shouldUseEmulator =
      useEmulator ?? const String.fromEnvironment('FT_USE_EMULATOR') == '1';
  if (!shouldUseEmulator) return;

  // Emulators run on the host machine. Android emulator must route via 10.0.2.2.
  final host = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
}
