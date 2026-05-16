import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';

const _googleWebClientId = String.fromEnvironment('FT_GOOGLE_WEB_CLIENT_ID');

/// Initialises Firebase. If `FT_USE_EMULATOR=1` is set (or `useEmulator` is
/// passed manually), wires both Auth + Firestore to the local emulator.
Future<void> bootstrapFirebase({bool? useEmulator}) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Native google_sign_in v7 requires a one-shot init. Web uses Firebase Auth's
  // popup flow in AuthRepository, so it does not need google_sign_in init.
  if (!kIsWeb) {
    final serverClientId = _googleWebClientId.trim().isEmpty
        ? null
        : _googleWebClientId.trim();
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
