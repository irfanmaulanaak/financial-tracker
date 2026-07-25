import 'package:financial_tracker/src/core/seeded_data.dart';
import 'package:financial_tracker/src/features/home/widgets/home_formatters.dart';
import 'package:financial_tracker/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => FtColors.setBrightness(Brightness.light));

  group('parseColor', () {
    test('maps legacy Tailwind seeds to theme palette (light)', () {
      FtColors.setBrightness(Brightness.light);
      expect(parseColor('#F59E0B'), FtColors.catFood);
      expect(parseColor('#3B82F6'), FtColors.catBills);
      expect(parseColor('#EC4899'), FtColors.catShopping);
      expect(parseColor('#10B981'), FtColors.catTransport);
      expect(parseColor('#8B5CF6'), FtColors.catEntertainment);
      expect(parseColor('#EF4444'), FtColors.catHealth);
      expect(parseColor('#64748B'), FtColors.catOther);
    });

    test('palette hexes switch with dark mode', () {
      FtColors.setBrightness(Brightness.light);
      final light = parseColor('#C4612A');
      FtColors.setBrightness(Brightness.dark);
      final dark = parseColor('#C4612A');
      expect(light, const Color(0xFFC4612A));
      expect(dark, const Color(0xFFe08a4a));
      expect(light, isNot(dark));
    });

    test('seeded categories use palette colors (theme-aware)', () {
      FtColors.setBrightness(Brightness.dark);
      for (final c in seededCategories) {
        final parsed = parseColor(c.color);
        // Every seed must resolve to a mapped pair, not the raw stored hex.
        expect(parsed, isNot(_raw(c.color)),
            reason: '${c.id} should map to a dark-mode variant');
      }
    });

    test('unknown hex falls through to raw parse', () {
      expect(parseColor('#123456'), const Color(0xFF123456));
    });
  });
}

Color _raw(String hex) =>
    Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
