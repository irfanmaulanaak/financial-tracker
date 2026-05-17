import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// 128-bit URL-safe random invite tokens. Single-use, regenerated per
/// invitation. The token doc id IS the credential — guessing it requires
/// 2^128 attempts, so we keep the `invites/{token}` read open.
///
/// Format: 22-character base64url (no padding) of 16 random bytes from
/// [Random.secure].
class InviteCode {
  static const int length = 22;
  static final _format = RegExp(r'^[A-Za-z0-9_-]{22}$');

  /// Generates a fresh 128-bit token.
  static String generate({Random? random}) {
    final rng = random ?? Random.secure();
    final bytes = Uint8List(16);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = rng.nextInt(256);
    }
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Validates the user-entered string looks like a token.
  static bool isValid(String code) => _format.hasMatch(code);

  /// Normalises raw input: trims surrounding whitespace + strips internal
  /// spaces/newlines. Does not touch character case — the token alphabet
  /// is case-sensitive.
  static String normalise(String input) =>
      input.trim().replaceAll(RegExp(r'\s+'), '');
}
