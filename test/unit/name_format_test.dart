import 'package:financial_tracker/src/features/household/name_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prettyName', () {
    test('capitalises a bare name', () {
      expect(prettyName('irfan'), 'Irfan');
    });

    test('strips the @domain from an email-like value', () {
      expect(prettyName('irfan@gmail.com'), 'Irfan');
    });

    test('falls back to Anggota when empty', () {
      expect(prettyName(''), 'Anggota');
    });
  });

  group('shortName', () {
    test('takes the first token of a full name', () {
      expect(shortName('Irfan Maulana Akbar'), 'Irfan');
      expect(shortName('Nadhifa Putri'), 'Nadhifa');
    });

    test('is a no-op on a single-token name (no space to split on)', () {
      expect(shortName('Irfanmaulanaak'), 'Irfanmaulanaak');
    });

    test('still strips an email domain first', () {
      expect(shortName('nadhifa@gmail.com'), 'Nadhifa');
    });
  });
}
