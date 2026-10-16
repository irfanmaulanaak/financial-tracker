import 'package:financial_tracker/src/features/home/widgets/home_header.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('greetingForHour', () {
    test('pagi before 11:00', () {
      expect(greetingForHour(0), 'Selamat pagi');
      expect(greetingForHour(10), 'Selamat pagi');
    });

    test('siang from 11:00 to before 15:00', () {
      expect(greetingForHour(11), 'Selamat siang');
      expect(greetingForHour(14), 'Selamat siang');
    });

    test('sore from 15:00 to before 18:00', () {
      expect(greetingForHour(15), 'Selamat sore');
      expect(greetingForHour(17), 'Selamat sore');
    });

    test('malam from 18:00 onward', () {
      expect(greetingForHour(18), 'Selamat malam');
      expect(greetingForHour(23), 'Selamat malam');
    });
  });
}
