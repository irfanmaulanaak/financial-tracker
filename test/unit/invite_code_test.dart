import 'dart:math';

import 'package:financial_tracker/src/core/invite_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InviteCode.generate', () {
    test('always returns 6 digits', () {
      for (var i = 0; i < 200; i++) {
        final code = InviteCode.generate();
        expect(code.length, 6);
        expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue,
            reason: 'got "$code"');
      }
    });

    test('preserves leading zeros for small numbers', () {
      // Seeded RNG that returns 0 on first nextInt call → "000000".
      final code = InviteCode.generate(random: _FixedRandom(0));
      expect(code, '000000');
    });

    test('preserves leading zeros for small non-zero numbers', () {
      final code = InviteCode.generate(random: _FixedRandom(42));
      expect(code, '000042');
    });
  });

  group('InviteCode.isValid', () {
    test('accepts exactly 6 digits', () {
      expect(InviteCode.isValid('123456'), isTrue);
      expect(InviteCode.isValid('000000'), isTrue);
    });

    test('rejects wrong length / non-digit', () {
      expect(InviteCode.isValid('12345'), isFalse);
      expect(InviteCode.isValid('1234567'), isFalse);
      expect(InviteCode.isValid('12345a'), isFalse);
      expect(InviteCode.isValid(''), isFalse);
    });
  });

  group('InviteCode.normalise', () {
    test('strips spaces, hyphens, letters', () {
      expect(InviteCode.normalise(' 123-456 '), '123456');
      expect(InviteCode.normalise('abc123def'), '123');
    });
  });
}

class _FixedRandom implements Random {
  _FixedRandom(this._value);
  final int _value;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => _value;
}
