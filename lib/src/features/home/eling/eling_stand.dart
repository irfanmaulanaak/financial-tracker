import 'package:flutter/material.dart';

import 'eling_draw.dart';
import 'eling_mood.dart';

/// Draws Eling standing (ported from `pgStand` in pangolin.js). [blink] is the
/// eye's vertical scale (1 = open, 0 = shut); only the Senang pose has an open
/// eye to blink.
void drawElingStand(Canvas canvas, ElingMood mood, {double blink = 1}) {
  final hore = mood == ElingMood.hore;
  if (hore) {
    pgRotate(canvas, -8, 40, 106, () => _stand(canvas, mood, blink));
  } else {
    _stand(canvas, mood, blink);
  }
}

void _rrect(Canvas c, double x, double y, double w, double h, double r,
        Paint p) =>
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
        p);

void _oval(Canvas c, double cx, double cy, double rx, double ry, Paint p) =>
    c.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
        p);

void _stand(Canvas canvas, ElingMood mood, double blink) {
  final hore = mood == ElingMood.hore;

  // Tail.
  final tail = parseSvgPath(
      'M32 72 C16 72 6 84 7 96 C8 104 14 107 19 104 C22 102 21 98 17 98 C15 92 22 86 34 88 Z');
  canvas.drawPath(tail, pgFill(pgGold));
  canvas.drawPath(tail, pgStroke(pgLine, 1.4));
  canvas.drawPath(
      parseSvgPath(
          'M13 83 q4.5 3.5 9 0.5 M9 90 q3.5 3 7 0.5 M20 77 q4 3.5 9 1'),
      pgStroke(pgLine, 1.3));

  // Legs (far pair darker), then belly.
  _rrect(canvas, 47, 90, 10, 16, 5, pgFill(pgSkinFar));
  _rrect(canvas, 84, 90, 10, 16, 5, pgFill(pgSkinFar));
  _rrect(canvas, 34, 88, 11, 18, 5.5, pgFill(pgSkinDark));
  pgDrawClaws(canvas, 34, 106);
  if (!hore) {
    _rrect(canvas, 72, 88, 11, 18, 5.5, pgFill(pgSkinDark));
    pgDrawClaws(canvas, 72, 106);
  }
  _oval(canvas, 60, 89, 30, 7.5, pgFill(pgSkin));

  // Scaly dome body.
  canvas.drawPath(pgDomePath, pgFill(pgGoldDark));
  pgClipped(canvas, pgDomePath, () {
    const rows = [92, 84, 76, 68, 60, 52, 44];
    for (var i = 0; i < rows.length; i++) {
      final y = rows[i].toDouble();
      for (var x = 14.0 + (i.isOdd ? 6 : 0); x <= 104; x += 12) {
        pgDrawScale(canvas, x, y, 7.5);
      }
    }
  });
  canvas.drawPath(pgDomePath, pgStroke(pgLine, 1.6));

  // Raised paw holding a coin (Hore only).
  if (hore) {
    pgRotate(canvas, 165, 80, 88,
        () => _rrect(canvas, 74.5, 86, 11, 17, 5.5, pgFill(pgSkinDark)));
    canvas.drawCircle(const Offset(76, 63), 6.5, pgFill(pgCoinGold));
    canvas.drawCircle(const Offset(76, 63), 6.5, pgStroke(pgLine, 1.4));
    canvas.drawCircle(const Offset(76, 63), 3.6, pgStroke(pgLine, 1));
  }

  // Head.
  canvas.drawPath(pgHeadPath, pgFill(pgSkin));
  pgClipped(canvas, pgHeadPath, () {
    pgDrawScale(canvas, 86, 70, 5);
    pgDrawScale(canvas, 88, 61, 5);
    pgDrawScale(canvas, 95, 56, 5);
  });
  _oval(canvas, 97, 72, 4, 2.6, pgFill(pgBlush.withValues(alpha: 0.8)));
  canvas.drawCircle(const Offset(113.2, 75.6), 2.4, pgFill(pgNose));

  // Face.
  if (hore) {
    canvas.drawPath(parseSvgPath('M96.5 65.5 q3.5 -4.5 7 0'),
        pgStroke(pgInk, 2.4));
    canvas.drawPath(parseSvgPath('M103 75.5 q3.5 4.5 7 0 z'), pgFill(pgNose));
  } else {
    pgScaleAround(canvas, 1, blink, 100, 64, () {
      _oval(canvas, 100, 64, 3, 3.7, pgFill(pgInk));
      canvas.drawCircle(const Offset(101.1, 62.6), 1.1, pgFill(Colors.white));
    });
    canvas.drawPath(parseSvgPath('M103.5 76 q3 2.4 6 0'), pgStroke(pgNose, 1.6));
  }
}
