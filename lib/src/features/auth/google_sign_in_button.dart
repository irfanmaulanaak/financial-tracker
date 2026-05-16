import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_repository.dart';

/// "Lanjutkan dengan Google" button. Handles its own busy state + surfacing
/// errors via `onError` callback (parent typically sets a banner). User
/// dismissal (canceled) is treated as a no-op silently.
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onError,
    this.label = 'Lanjutkan dengan Google',
    this.enabled = true,
  });

  final void Function(String message) onError;
  final String label;
  final bool enabled;

  @override
  ConsumerState<GoogleSignInButton> createState() =>
      _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // Router redirect takes over from here.
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      widget.onError(_friendlyGoogleError(e));
    } on FirebaseAuthException catch (e) {
      widget.onError(_friendlyFirebaseError(e));
    } catch (e) {
      widget.onError('Gagal masuk dengan Google: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: (widget.enabled && !_busy) ? _go : null,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.g_mobiledata, size: 28),
      label: Text(widget.label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

String _friendlyGoogleError(GoogleSignInException e) => switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Dibatalkan',
      GoogleSignInExceptionCode.interrupted => 'Proses terganggu, coba lagi',
      GoogleSignInExceptionCode.clientConfigurationError =>
        'Konfigurasi Google Sign-In belum lengkap (cek Firebase Console + flutterfire configure)',
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Provider Google belum diaktifkan di Firebase Console',
      GoogleSignInExceptionCode.uiUnavailable =>
        'UI Google Sign-In tidak tersedia di platform ini',
      _ => 'Gagal masuk dengan Google: ${e.description ?? e.code.name}',
    };

String _friendlyFirebaseError(FirebaseAuthException e) => switch (e.code) {
      'account-exists-with-different-credential' =>
        'Akun email ini sudah dibuat dengan metode lain. Masuk pakai email/password dulu.',
      'invalid-credential' => 'Kredensial Google tidak valid',
      'user-disabled' => 'Akun dinonaktifkan',
      'network-request-failed' => 'Tidak ada koneksi internet',
      'missing-id-token' => 'Google tidak mengembalikan ID token',
      _ => 'Gagal: ${e.message ?? e.code}',
    };
