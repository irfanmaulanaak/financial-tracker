import 'dart:math';

/// 6-digit numeric invite codes. Single-use, regenerated per invitation.
/// Generated client-side; collision handled by Firestore (doc create fails on
/// existing ID, caller retries).
class InviteCode {
  static const int length = 6;
  static final _digits = RegExp(r'^\d{6}$');

  /// Generates a random 6-digit code with leading zeros preserved.
  static String generate({Random? random}) {
    final rng = random ?? Random.secure();
    final value = rng.nextInt(1000000);
    return value.toString().padLeft(length, '0');
  }

  /// Validates the user-entered string looks like a code (6 digits).
  static bool isValid(String code) => _digits.hasMatch(code);

  /// Normalises raw input: strips whitespace + non-digits.
  static String normalise(String input) =>
      input.replaceAll(RegExp(r'\D'), '').trim();
}
