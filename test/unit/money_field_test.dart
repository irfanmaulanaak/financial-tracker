import 'package:financial_tracker/src/features/record_common/money_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _apply(String oldText, String newText) {
  final formatter = ThousandsSeparatorFormatter();
  return formatter.formatEditUpdate(
    TextEditingValue(
      text: oldText,
      selection: TextSelection.collapsed(offset: oldText.length),
    ),
    TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    ),
  );
}

void main() {
  group('ThousandsSeparatorFormatter', () {
    test('empty input stays empty', () {
      final out = _apply('', '');
      expect(out.text, '');
      expect(out.selection.baseOffset, 0);
    });

    test('single digit passes through', () {
      final out = _apply('', '1');
      expect(out.text, '1');
      expect(out.selection.baseOffset, 1);
    });

    test('1000 → 1.000', () {
      final out = _apply('1', '1000');
      expect(out.text, '1.000');
    });

    test('1234567 → 1.234.567', () {
      final out = _apply('123456', '1234567');
      expect(out.text, '1.234.567');
    });

    test('typing on top of grouped text re-groups cleanly', () {
      final out = _apply('1.000', '1.0000');
      expect(out.text, '10.000');
    });

    test('non-digits stripped', () {
      final out = _apply('', 'Rp 1.234');
      expect(out.text, '1.234');
    });

    test('cursor lands at end of text after formatting', () {
      final out = _apply('1.000', '10000');
      expect(out.text, '10.000');
      expect(out.selection.baseOffset, out.text.length);
    });
  });
}
