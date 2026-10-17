import 'package:financial_tracker/src/features/goals/widgets/goal_bubble.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('goalBubbleCopy', () {
    test('0 progress → invite to start, no second line', () {
      final b = goalBubbleCopy(current: 0, target: 200000000, monthlyContrib: 10000000);
      expect(b.line1, 'Yuk mulai setor pertama.');
      expect(b.line2, isNull);
    });

    test('60% with a monthly contribution → progress + months-left line', () {
      final b = goalBubbleCopy(
        current: 120000000,
        target: 200000000,
        monthlyContrib: 16000000,
      );
      expect(b.line1, 'Sudah 60%! Kurang Rp80 jt lagi.');
      expect(b.line2, 'Sekitar 5 bulan lagi sampai.');
    });

    test('60% without a monthly contribution → no second line', () {
      final b = goalBubbleCopy(
        current: 120000000,
        target: 200000000,
        monthlyContrib: 0,
      );
      expect(b.line1, 'Sudah 60%! Kurang Rp80 jt lagi.');
      expect(b.line2, isNull);
    });

    test('100% or more → celebration line, no second line', () {
      final at = goalBubbleCopy(current: 200000000, target: 200000000, monthlyContrib: 10000000);
      expect(at.line1, 'Tercapai! Selamat ya.');
      expect(at.line2, isNull);

      final over = goalBubbleCopy(current: 250000000, target: 200000000, monthlyContrib: 10000000);
      expect(over.line1, 'Tercapai! Selamat ya.');
      expect(over.line2, isNull);
    });

    test('text joins both lines with a newline when present', () {
      final b = goalBubbleCopy(
        current: 120000000,
        target: 200000000,
        monthlyContrib: 16000000,
      );
      expect(b.text, '${b.line1}\n${b.line2}');
    });
  });
}
