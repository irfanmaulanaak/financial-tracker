import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'eling_draw.dart';
import 'eling_mood.dart';

/// Draws Eling curled into a ball (ported from `pgBall` in pangolin.js).
///
/// [rollDegrees] spins the coin cluster (the `pg-roll` group) around its
/// centre during the entrance roll. [showFace] draws the peeking snout and the
/// mood extras (sweat drop / nightcap) — on during the resting ball pose, off
/// while rolling so a static face doesn't ride on the spinning coins. [blink]
/// is the Ngirit peek-eye's vertical scale (1 = open, 0 = shut).
void drawElingBall(
  Canvas canvas,
  ElingMood mood, {
  required double rollDegrees,
  required bool showFace,
  double blink = 1,
}) {
  final peeking = mood == ElingMood.ngirit || mood == ElingMood.bobo;
  if (showFace && peeking) _peek(canvas, mood, blink);

  // Spinning coin cluster.
  pgRotate(canvas, rollDegrees, 60, 76, () {
    canvas.drawCircle(const Offset(60, 76), 30, pgFill(pgGoldDark));
    final clip = Path()
      ..addOval(Rect.fromCircle(center: const Offset(60, 76), radius: 30));
    pgClipped(canvas, clip, () {
      _ring(canvas, 24, 13, 8.5, 0);
      _ring(canvas, 14, 8, 7.5, 0.35);
      canvas.drawCircle(const Offset(60, 76), 6.5, pgFill(pgGold));
      canvas.drawCircle(const Offset(60, 76), 6.5, pgStroke(pgLine, 1.4));
      canvas.drawPath(parseSvgPath('M57.4 76 a2.6 2.6 0 1 1 2.6 2.6'),
          pgStroke(pgLine, 1.3));
    });
    canvas.drawCircle(const Offset(60, 76), 30, pgStroke(pgLine, 1.8));
  });

  // Rim highlight.
  canvas.drawPath(parseSvgPath('M38 62 A25 25 0 0 1 52 51'),
      pgStroke(Colors.white.withValues(alpha: 0.5), 3));

  if (showFace && mood == ElingMood.ngirit) {
    // Sweat drop + worry lines.
    canvas.drawPath(
        parseSvgPath('M101 54 q-4.2 6 0 9 q4.2 -3 0 -9z'), pgFill(pgSweat));
    canvas.drawPath(parseSvgPath('M24 66 q-4 6 0 12 M17 62 q-5 10 0 20'),
        pgStroke(pgLine.withValues(alpha: 0.55), 1.6));
  }
  if (showFace && mood == ElingMood.bobo) {
    // Nightcap + "z z".
    canvas.drawPath(
        parseSvgPath('M42 52 Q48 22 86 28 Q80 36 74 48 Z'), pgFill(pgNightcap));
    canvas.drawPath(parseSvgPath('M40 53.5 Q58 40 76 49.5'),
        pgStroke(Colors.white, 6));
    canvas.drawCircle(const Offset(88, 28), 5, pgFill(Colors.white));
    _zz(canvas);
  }
}

/// The snout peeking out from behind the ball (pgPeek). [mood] is ngirit or
/// bobo; ngirit gets an open worried eye, bobo a closed sleeping one.
void _peek(Canvas canvas, ElingMood mood, double blink) {
  canvas.drawPath(
      parseSvgPath(
          'M80 66 C92 62 102 72 105 82 C105.5 85.5 103 87 100 86 C95 84.5 88 86 82 85 Z'),
      pgFill(pgSkin));
  canvas.drawCircle(const Offset(104.2, 83.2), 2.1, pgFill(pgNose));
  if (mood == ElingMood.ngirit) {
    pgScaleAround(canvas, 1, blink, 95, 75, () {
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(95, 75), width: 5.2, height: 6.4),
          pgFill(pgInk));
      canvas.drawCircle(const Offset(95.9, 73.8), 0.95, pgFill(Colors.white));
    });
    canvas.drawPath(parseSvgPath('M91.8 71 L98.4 68.4'), pgStroke(pgInk, 1.9));
  } else {
    canvas.drawPath(parseSvgPath('M92.5 76 q2.5 2.4 5 0'), pgStroke(pgInk, 2));
  }
}

void _ring(Canvas canvas, double radius, int count, double r, double offset) {
  for (var k = 0; k < count; k++) {
    final a = offset + (k * 2 * math.pi) / count;
    final x = 60 + radius * math.cos(a);
    final y = 76 + radius * math.sin(a);
    canvas.drawCircle(Offset(x, y), r, pgFill(pgGold));
    canvas.drawCircle(Offset(x, y), r, pgStroke(pgLine, 1.4));
    canvas.drawCircle(
        Offset(x + 0.45 * r * math.cos(a), y + 0.45 * r * math.sin(a)),
        1.6,
        pgFill(pgShine));
  }
}

void _zz(Canvas canvas) {
  void z(String s, double x, double y, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: GoogleFonts.fredoka(
          fontWeight: FontWeight.w600,
          fontSize: size,
          color: pgNightcap,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // SVG text y is the baseline; TextPainter paints from the top, so lift it.
    tp.paint(canvas, Offset(x, y - tp.height * 0.8));
  }

  z('z', 98, 22, 13);
  z('z', 107, 12, 10);
}
