import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Initialises Firebase. If `FT_USE_EMULATOR=1` is set (or `useEmulator` is
/// passed manually), wires both Auth + Firestore to the local emulator.
Future<void> bootstrapFirebase({bool? useEmulator}) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final shouldUseEmulator = useEmulator ??
      const String.fromEnvironment('FT_USE_EMULATOR') == '1';
  if (!shouldUseEmulator) return;

  // Emulators run on the host machine. Android emulator must route via 10.0.2.2.
  final host = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
}
