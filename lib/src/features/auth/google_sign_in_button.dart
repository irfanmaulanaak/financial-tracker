import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../theme.dart';
import 'auth_repository.dart';

/// "Lanjutkan dengan Google" — outlined button on cream surface with the
/// official 4-color "G" mark drawn via [CustomPaint] (no extra asset needed).
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
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } on GoogleSignInException catch (e) {
      debugPrint(
        'Google Sign-In failed: ${e.code.name} ${e.description ?? ''}',
      );
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
    return OutlinedButton(
      onPressed: (widget.enabled && !_busy) ? _go : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FtColors.ink2,
                  ),
                )
              : const SizedBox(
                  width: 18,
                  height: 18,
                  child: CustomPaint(painter: _GoogleGPainter()),
                ),
          const SizedBox(width: 12),
          Text(widget.label),
        ],
      ),
    );
  }
}

/// Hand-drawn approximation of the Google "G" logo (4-color). Good enough for
/// an internal app; avoids bundling an asset.
class _GoogleGPainter extends CustomPainter {
  const _GoogleGPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final inner = r * 0.55;

    void arc(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r - inner;
      final rect = Rect.fromCircle(
        center: Offset(cx, cy),
        radius: (r + inner) / 2,
      );
      canvas.drawArc(
        rect,
        startDeg * 3.1415926535 / 180,
        sweepDeg * 3.1415926535 / 180,
        false,
        paint,
      );
    }

    // Red top, Yellow left, Green bottom, Blue right (clockwise from -90°)
    arc(-90, 90, const Color(0xFFEA4335)); // red
    arc(180, 90, const Color(0xFFFBBC05)); // yellow
    arc(90, 90, const Color(0xFF34A853)); // green
    arc(0, 90, const Color(0xFF4285F4)); // blue

    // Horizontal bar (right side of the G)
    final bar = Paint()..color = const Color(0xFF4285F4);
    final barRect = Rect.fromLTWH(cx, cy - 1.6, r, 3.2);
    canvas.drawRect(barRect, bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _friendlyGoogleError(GoogleSignInException e) => switch (e.code) {
  GoogleSignInExceptionCode.canceled =>
    'Google Sign-In dibatalkan atau Credential Manager gagal. Tutup app lalu rebuild kalau baru update Firebase config.',
  GoogleSignInExceptionCode.interrupted => 'Proses terganggu, coba lagi',
  GoogleSignInExceptionCode.clientConfigurationError =>
    'Google Sign-In native belum punya OAuth client. Cek SHA Android lalu unduh ulang google-services.json.',
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
  'operation-not-allowed' =>
    'Provider Google belum diaktifkan di Firebase Console',
  'popup-blocked' => 'Popup Google diblokir browser',
  'popup-closed-by-user' => 'Dibatalkan',
  'user-disabled' => 'Akun dinonaktifkan',
  'network-request-failed' => 'Tidak ada koneksi internet',
  'missing-id-token' => 'Google tidak mengembalikan ID token',
  _ => 'Gagal: ${e.message ?? e.code}',
};
