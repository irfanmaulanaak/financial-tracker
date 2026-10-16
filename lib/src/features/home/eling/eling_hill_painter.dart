import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Scene geometry, all in the mockup's design units (see home.html). The hill
/// band is the slice of the mockup's 390x412 scene from y=232 down to y=412,
/// re-based to a 390x180 box so the speech bubble sits at the top and the hill
/// at the bottom.
const double kSceneW = 390;
const double kSceneH = 180;

/// Eling's sprite box size (mockup `S`) and the offsets of his base point.
const double kElingSize = 84;
const double kElingHalf = 60 / 120 * kElingSize; // 42 — half the sprite
const double kElingBase = 106 / 120 * kElingSize; // 74.2 — base y in sprite
const double kBallRadius = 30 / 120 * kElingSize; // 21 — rolling radius

const double _startX = 26;
const double _houseX = 352;

/// Builds the payday path (a shallow upward bow) in design units.
Path buildTrackPath() => Path()
  ..moveTo(0, 142)
  ..quadraticBezierTo(195, 102, 390, 142);

/// The payday path with its sampled lengths — the cycle-start end (`l0`),
/// payday end (`l1`), and helpers to place things along it.
class TrackGeometry {
  TrackGeometry._(this.path, this.metric, this.length, this.l0, this.l1,
      this.p0, this.p1);

  final Path path;
  final ui.PathMetric metric;
  final double length;
  final double l0, l1;
  final Offset p0, p1;

  factory TrackGeometry() {
    final path = buildTrackPath();
    final metric = path.computeMetrics().first;
    final length = metric.length;
    double lenAtX(double x) {
      var lo = 0.0, hi = length;
      for (var i = 0; i < 30; i++) {
        final mid = (lo + hi) / 2;
        final px = metric.getTangentForOffset(mid)!.position.dx;
        if (px < x) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      return lo;
    }

    final l0 = lenAtX(_startX);
    final l1 = lenAtX(_houseX);
    return TrackGeometry._(
      path,
      metric,
      length,
      l0,
      l1,
      metric.getTangentForOffset(l0)!.position,
      metric.getTangentForOffset(l1)!.position,
    );
  }

  Offset pointAt(double len) =>
      metric.getTangentForOffset(len.clamp(0, length))!.position;

  Path extract(double a, double b) => metric.extractPath(a, b);
}

/// Scene colors derived from the active "Warna" palette (DESIGN.md section 2).
class ElingSceneColors {
  const ElingSceneColors({
    required this.hill,
    required this.emptyPath,
    required this.filledPath,
    required this.dot,
    required this.houseBody,
    required this.roof,
    required this.door,
  });
  final Color hill, emptyPath, filledPath, dot, houseBody, roof, door;
}

/// Paints the hill, the payday path (empty track + the green progress that
/// follows Eling), the cycle-start dot and the payday house.
class ElingHillPainter extends CustomPainter {
  ElingHillPainter({
    required this.geo,
    required this.greenLen,
    required this.colors,
  });

  final TrackGeometry geo;

  /// Length of the green (walked) portion, from `l0` to here.
  final double greenLen;
  final ElingSceneColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / kSceneW, size.height / kSceneH);

    // Hill fill.
    final hill = Path()
      ..moveTo(0, 142)
      ..quadraticBezierTo(195, 102, 390, 142)
      ..lineTo(390, 180)
      ..lineTo(0, 180)
      ..close();
    canvas.drawPath(hill, Paint()..color = colors.hill);

    Paint track(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Empty track (cycle start → payday) then the green walked portion.
    canvas.drawPath(geo.extract(geo.l0, geo.l1), track(colors.emptyPath));
    if (greenLen > geo.l0) {
      canvas.drawPath(geo.extract(geo.l0, greenLen), track(colors.filledPath));
    }

    // Cycle-start dot.
    canvas.drawCircle(geo.p0, 6, Paint()..color = colors.dot);

    // Payday house at the end of the path.
    canvas.save();
    canvas.translate(geo.p1.dx, geo.p1.dy + 2);
    canvas.drawPath(
      Path()
        ..moveTo(-15, 0)
        ..lineTo(-15, -17)
        ..lineTo(0, -30)
        ..lineTo(15, -17)
        ..lineTo(15, 0)
        ..close(),
      Paint()..color = colors.houseBody,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-19, -15)
        ..lineTo(0, -32)
        ..lineTo(19, -15),
      Paint()
        ..color = colors.roof
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4.5, -12, 9, 12), const Radius.circular(2)),
      Paint()..color = colors.door,
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(ElingHillPainter old) =>
      old.greenLen != greenLen || old.colors != colors;
}
