import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/app_lock.dart';

void main() {
  group('hashPin', () {
    test('deterministic untuk pin+salt sama', () {
      expect(hashPin('123456', 'abc'), hashPin('123456', 'abc'));
    });

    test('salt beda → hash beda (PIN sama)', () {
      expect(hashPin('123456', 'a'), isNot(hashPin('123456', 'b')));
    });

    test('pin beda → hash beda', () {
      expect(hashPin('123456', 'a'), isNot(hashPin('654321', 'a')));
    });

    test('hash bukan PIN mentah', () {
      final h = hashPin('123456', 'salt');
      expect(h, isNot(contains('123456')));
      expect(h.length, 64); // sha-256 hex
    });
  });

  group('generateSalt', () {
    test('32 hex chars, deterministik dengan seed', () {
      final s = generateSalt(rng: Random(42));
      expect(s.length, 32);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(s), isTrue);
      expect(generateSalt(rng: Random(42)), s);
      expect(generateSalt(rng: Random(43)), isNot(s));
    });
  });
}
