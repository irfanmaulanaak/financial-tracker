import 'dart:math' as math;

import 'package:financial_tracker/src/features/home/eling/eling_hill_painter.dart';
import 'package:financial_tracker/src/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _linear(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4) as double;

double _luminance(Color c) =>
    0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

/// WCAG 2.x contrast ratio, 1:1 (no contrast) .. 21:1 (black on white).
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

const _kAA = 4.5;

/// WCAG AA for UI components and large text (3:1). The "Warna" accent (`clay`)
/// is an action color — links, the active tab, progress fills — not body text,
/// so it's held to this level. Daun's accent (`#1F8A5B`, fixed by DESIGN.md)
/// is a mid-tone green that can't reach 4.5:1 against white either way, which
/// is fine for its role.
const _kAALarge = 3.0;

void main() {
  tearDown(() {
    FtColors.setBrightness(Brightness.light);
    FtColors.setPalette(FtPalette.daun);
  });

  group('default palette (Daun) matches DESIGN.md', () {
    test('light', () {
      FtColors.setBrightness(Brightness.light);
      FtColors.setPalette(FtPalette.daun);
      expect(FtColors.clay.toARGB32(), 0xFF1F8A5B);
      expect(FtColors.bg.toARGB32(), 0xFFFFFFFF);
      expect(FtColors.hero.toARGB32(), 0xFFEEF7F1);
      expect(FtColors.ink.toARGB32(), 0xFF18231D);
      expect(FtColors.fab.toARGB32(), 0xFFF7BE34);
      expect(FtColors.onFab.toARGB32(), 0xFF18231D);
    });

    test('dark', () {
      FtColors.setBrightness(Brightness.dark);
      FtColors.setPalette(FtPalette.daun);
      expect(FtColors.clay.toARGB32(), 0xFF4CC38A);
      expect(FtColors.bg.toARGB32(), 0xFF0F1512);
      expect(FtColors.hero.toARGB32(), 0xFF14251C);
      expect(FtColors.ink.toARGB32(), 0xFFEAF2EC);
      expect(FtColors.fab.toARGB32(), 0xFFF7BE34);
    });
  });

  group('Hangat palette still matches the original look exactly', () {
    test('light', () {
      FtColors.setBrightness(Brightness.light);
      FtColors.setPalette(FtPalette.hangat);
      expect(FtColors.clay.toARGB32(), 0xFFB8431F);
      expect(FtColors.bg.toARGB32(), 0xFFFFF6EC);
      expect(FtColors.surface.toARGB32(), 0xFFFFFFFF);
      expect(FtColors.ink.toARGB32(), 0xFF2A160C);
      expect(FtColors.fab.toARGB32(), 0xFF7A4A30);
    });

    test('dark', () {
      FtColors.setBrightness(Brightness.dark);
      FtColors.setPalette(FtPalette.hangat);
      expect(FtColors.clay.toARGB32(), 0xFFFFB38A);
      expect(FtColors.bg.toARGB32(), 0xFF15110E);
      expect(FtColors.surface.toARGB32(), 0xFF211B17);
      expect(FtColors.ink.toARGB32(), 0xFFF6ECE4);
      expect(FtColors.fab.toARGB32(), 0xFFFFB38A);
    });
  });

  for (final palette in FtPalette.values) {
    for (final brightness in Brightness.values) {
      group('${palette.name} / ${brightness.name}', () {
        setUp(() {
          FtColors.setBrightness(brightness);
          FtColors.setPalette(palette);
        });

        test('body text meets AA (4.5:1) on bg and surface', () {
          expect(_contrast(FtColors.ink, FtColors.bg), greaterThanOrEqualTo(_kAA));
          expect(
              _contrast(FtColors.ink, FtColors.surface), greaterThanOrEqualTo(_kAA));
          expect(
              _contrast(FtColors.ink2, FtColors.bg), greaterThanOrEqualTo(_kAA));
          expect(_contrast(FtColors.ink2, FtColors.surface),
              greaterThanOrEqualTo(_kAA));
        });

        test('onFab meets AA (4.5:1) on fab', () {
          expect(
              _contrast(FtColors.onFab, FtColors.fab), greaterThanOrEqualTo(_kAA));
        });

        test('accent text meets AA for UI components (3:1) on clay', () {
          // Mirrors buildTheme's onPrimary: white in light mode, onPeach in
          // dark mode (see theme.dart ColorScheme construction). `clay` is an
          // action color, so AA-large (3:1) is the applicable level.
          final onAccent =
              brightness == Brightness.dark ? FtColors.onPeach : Colors.white;
          expect(_contrast(onAccent, FtColors.clay),
              greaterThanOrEqualTo(_kAALarge));
        });

        test('onPeach meets AA (4.5:1) on peach', () {
          expect(_contrast(FtColors.onPeach, FtColors.peach),
              greaterThanOrEqualTo(_kAA));
        });

        test('onHero meets AA (4.5:1) on hero', () {
          // The hero panel + header text/number all sit on `hero` and use
          // `onHero` (DESIGN.md section 2).
          expect(_contrast(FtColors.onHero, FtColors.hero),
              greaterThanOrEqualTo(_kAA));
        });

        test('Eling path, dot and date labels stand out on the hill', () {
          // Regression: in Laut/Hutan/Hangat dark the accent equals `hero`, so
          // the payday path and dot vanished, and the `ink2` labels were light
          // text on a light hero.
          final c = ElingSceneColors.fromTheme();
          expect(_contrast(c.filledPath, FtColors.hero),
              greaterThanOrEqualTo(_kAALarge));
          expect(_contrast(FtColors.onHero, c.hill), greaterThanOrEqualTo(_kAA));
        });
      });
    }
  }
}
