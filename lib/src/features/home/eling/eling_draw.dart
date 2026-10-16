import 'package:flutter/material.dart';

/// Shared drawing primitives for Eling. The pangolin geometry is ported
/// verbatim from `pangolin.js` (the approved mockup) by reusing its exact SVG
/// path strings through [parseSvgPath], so shapes/sizes/positions match the
/// 120x120 coordinate space one-to-one.

// Eling's own colors are his identity (gold coins, tan skin) and stay fixed
// across every "Warna" palette — only the scene (hill/path/house) follows the
// palette. These mirror the `PG` table in pangolin.js.
const pgGold = Color(0xFFEBA93F);
const pgGoldDark = Color(0xFFC98A2E);
const pgLine = Color(0xFFB5711A);
const pgShine = Color(0xFFF8D47E);
const pgSkin = Color(0xFFF3D0AA);
const pgSkinDark = Color(0xFFDFAE80);
const pgSkinFar = Color(0xFFC99566);
const pgInk = Color(0xFF2A1E16);
const pgNose = Color(0xFF6B4330);
const pgBlush = Color(0xFFF49A88);

/// The gold used for the held/scale coins drawn with `#F7BE34` in the mockup
/// (raised-paw coin + confetti). Kept gold in every palette, per DESIGN.md.
const pgCoinGold = Color(0xFFF7BE34);

const pgNightcap = Color(0xFF3E5BA9);
const pgSweat = Color(0xFF7CC4F0);

/// Dome + head clip shapes (PG_DOME / PG_HEAD in pangolin.js).
final pgDomePath = parseSvgPath(
    'M24 88 C20 62 40 44 64 44 C84 44 98 58 96 78 C95 84 92 87 88 88 C66 92 44 92 24 88 Z');
final pgHeadPath = parseSvgPath(
    'M84 58 C96 52 108 60 114 74 C115 78 112 80 108 79 C100 78 92 80 86 78 Z');

Paint pgFill(Color c) => Paint()
  ..color = c
  ..style = PaintingStyle.fill
  ..isAntiAlias = true;

Paint pgStroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

/// One coin scale (pgScale in the mockup): a gold disc, dark outline, and a
/// small bright shine arc.
void pgDrawScale(Canvas canvas, double x, double y, double r) {
  canvas.drawCircle(Offset(x, y), r, pgFill(pgGold));
  canvas.drawCircle(Offset(x, y), r, pgStroke(pgLine, 1.4));
  final shine = Path()
    ..moveTo(x - r * 0.5, y + r * 0.35)
    ..relativeQuadraticBezierTo(r * 0.3, r * 0.38, r * 0.72, r * 0.35);
  canvas.drawPath(shine, pgStroke(pgShine, 1.5));
}

/// Three little claw strokes at the foot of a leg (pgClaws in the mockup).
void pgDrawClaws(Canvas canvas, double x, double y) {
  final paint = pgStroke(const Color(0xFFFFF3DE), 1.5);
  for (var i = 0; i < 3; i++) {
    final sx = x + 2.5 + i * 3;
    canvas.drawLine(Offset(sx, y - 2.5), Offset(sx + 1.6, y + 0.1), paint);
  }
}

/// Runs [body] with the canvas clipped to [path].
void pgClipped(Canvas canvas, Path path, VoidCallback body) {
  canvas.save();
  canvas.clipPath(path);
  body();
  canvas.restore();
}

/// SVG `rotate(deg cx cy)` around a pivot, for [body].
void pgRotate(Canvas canvas, double degrees, double cx, double cy,
    VoidCallback body) {
  canvas.save();
  canvas.translate(cx, cy);
  canvas.rotate(degrees * 3.141592653589793 / 180);
  canvas.translate(-cx, -cy);
  body();
  canvas.restore();
}

/// SVG `scale(sx sy)` around a pivot, for [body].
void pgScaleAround(Canvas canvas, double sx, double sy, double cx, double cy,
    VoidCallback body) {
  canvas.save();
  canvas.translate(cx, cy);
  canvas.scale(sx, sy);
  canvas.translate(-cx, -cy);
  body();
  canvas.restore();
}

/// A minimal SVG path-data parser — enough for the pangolin's path strings
/// (M/L/H/V/C/Q/A/Z, absolute and relative). Lets us reuse pangolin.js's exact
/// `d=""` strings so the ported geometry can't drift from the mockup.
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = RegExp(r'[a-zA-Z]|-?\d*\.?\d+(?:[eE]-?\d+)?')
      .allMatches(d)
      .map((m) => m.group(0)!)
      .toList();
  var i = 0;
  double cx = 0, cy = 0, startX = 0, startY = 0;
  var cmd = '';
  double n() => double.parse(tokens[i++]);

  bool isLetter(String t) => RegExp(r'[a-zA-Z]').hasMatch(t);

  while (i < tokens.length) {
    if (isLetter(tokens[i])) {
      cmd = tokens[i];
      i++;
    }
    switch (cmd) {
      case 'M':
        cx = n();
        cy = n();
        path.moveTo(cx, cy);
        startX = cx;
        startY = cy;
        cmd = 'L';
      case 'm':
        cx += n();
        cy += n();
        path.moveTo(cx, cy);
        startX = cx;
        startY = cy;
        cmd = 'l';
      case 'L':
        cx = n();
        cy = n();
        path.lineTo(cx, cy);
      case 'l':
        cx += n();
        cy += n();
        path.lineTo(cx, cy);
      case 'H':
        cx = n();
        path.lineTo(cx, cy);
      case 'h':
        cx += n();
        path.lineTo(cx, cy);
      case 'V':
        cy = n();
        path.lineTo(cx, cy);
      case 'v':
        cy += n();
        path.lineTo(cx, cy);
      case 'C':
        final x1 = n(), y1 = n(), x2 = n(), y2 = n(), x = n(), y = n();
        path.cubicTo(x1, y1, x2, y2, x, y);
        cx = x;
        cy = y;
      case 'c':
        final x1 = cx + n(), y1 = cy + n();
        final x2 = cx + n(), y2 = cy + n();
        final x = cx + n(), y = cy + n();
        path.cubicTo(x1, y1, x2, y2, x, y);
        cx = x;
        cy = y;
      case 'Q':
        final x1 = n(), y1 = n(), x = n(), y = n();
        path.quadraticBezierTo(x1, y1, x, y);
        cx = x;
        cy = y;
      case 'q':
        final x1 = cx + n(), y1 = cy + n();
        final x = cx + n(), y = cy + n();
        path.quadraticBezierTo(x1, y1, x, y);
        cx = x;
        cy = y;
      case 'A':
        final rx = n(), ry = n(), rot = n(), large = n(), sweep = n();
        final x = n(), y = n();
        path.arcToPoint(Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: rot,
            largeArc: large != 0,
            clockwise: sweep != 0);
        cx = x;
        cy = y;
      case 'a':
        final rx = n(), ry = n(), rot = n(), large = n(), sweep = n();
        final x = cx + n(), y = cy + n();
        path.arcToPoint(Offset(x, y),
            radius: Radius.elliptical(rx, ry),
            rotation: rot,
            largeArc: large != 0,
            clockwise: sweep != 0);
        cx = x;
        cy = y;
      case 'Z' || 'z':
        path.close();
        cx = startX;
        cy = startY;
    }
  }
  return path;
}
