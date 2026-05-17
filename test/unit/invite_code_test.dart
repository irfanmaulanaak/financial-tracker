import 'dart:math';

import 'package:financial_tracker/src/core/invite_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InviteCode.generate', () {
    test('always returns 22 url-safe base64 characters', () {
      for (var i = 0; i < 200; i++) {
        final code = InviteCode.generate();
        expect(code.length, 22);
        expect(RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(code), isTrue,
            reason: 'got "$code"');
      }
    });

    test('returns distinct tokens across many draws (sanity check)', () {
      final seen = <String>{};
      for (var i = 0; i < 1000; i++) {
        seen.add(InviteCode.generate());
      }
      expect(seen.length, 1000);
    });

    test('encodes all-zero bytes deterministically', () {
      final code = InviteCode.generate(random: _AllZerosRandom());
      expect(code, 'AAAAAAAAAAAAAAAAAAAAAA');
      expect(InviteCode.isValid(code), isTrue);
    });
  });

  group('InviteCode.isValid', () {
    test('accepts a freshly generated token', () {
      expect(InviteCode.isValid(InviteCode.generate()), isTrue);
    });

    test('rejects wrong length / unsupported chars', () {
      expect(InviteCode.isValid('short'), isFalse);
      expect(InviteCode.isValid('a' * 21), isFalse);
      expect(InviteCode.isValid('a' * 23), isFalse);
      expect(InviteCode.isValid('!' * 22), isFalse);
      expect(InviteCode.isValid(''), isFalse);
      // Legacy 6-digit codes must no longer be accepted.
      expect(InviteCode.isValid('123456'), isFalse);
    });
  });

  group('InviteCode.normalise', () {
    test('trims whitespace and strips internal spaces', () {
      expect(InviteCode.normalise(' abc 123 _de-f '), 'abc123_de-f');
      expect(InviteCode.normalise('abc\n123'), 'abc123');
    });

    test('preserves case (token alphabet is case-sensitive)', () {
      expect(InviteCode.normalise('AbCdEf'), 'AbCdEf');
    });
  });
}

class _AllZerosRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
