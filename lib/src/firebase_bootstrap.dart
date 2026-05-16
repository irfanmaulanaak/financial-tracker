import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

/// Initialises Firebase. If `FT_USE_EMULATOR=1` is set (or `useEmulator` is
/// passed manually), wires both Auth + Firestore to the local emulator.
Future<void> bootstrapFirebase({bool? useEmulator}) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // google_sign_in v7 requires a one-shot init. On iOS the clientId is read
  // from GoogleService-Info.plist (CLIENT_ID); on Android it's auto-detected
  // from google-services.json (oauth_client). Both files must be regenerated
  // via `flutterfire configure` AFTER enabling Google Sign-in in the Firebase
  // Console. Init failure is logged but non-fatal so email/password still
  // works if Google isn't configured yet.
  try {
    await GoogleSignIn.instance.initialize();
  } catch (e, st) {
    debugPrint('Google Sign-In init failed: $e\n$st');
  }

  final shouldUseEmulator = useEmulator ??
      const String.fromEnvironment('FT_USE_EMULATOR') == '1';
  if (!shouldUseEmulator) return;

  // Emulators run on the host machine. Android emulator must route via 10.0.2.2.
  final host = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
}
