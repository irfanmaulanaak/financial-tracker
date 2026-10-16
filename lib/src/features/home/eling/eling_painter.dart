import 'package:flutter/material.dart';

import 'eling_ball.dart';
import 'eling_draw.dart';
import 'eling_mood.dart';
import 'eling_stand.dart';

/// Paints Eling into its 120x120 coordinate space (scaled to the widget), the
/// same way pangolin.js's `render(t)` does: a shadow, optional confetti, and a
/// cross-faded ball + standing body.
///
/// The animation values are passed in so one controller in the scene can drive
/// everything and this painter stays a pure function of its inputs.
class ElingPainter extends CustomPainter {
  ElingPainter({
    required this.mood,
    required this.standness,
    required this.rollDegrees,
    required this.standScale,
    required this.breathe,
    required this.blink,
    required this.rolling,
  });

  /// 0 = curled ball, 1 = standing. Drives the ball/stand cross-fade exactly as
  /// the mockup's `standness(t)` → `u`.
  final double standness;

  /// Rotation of the coin cluster during the roll.
  final double rollDegrees;

  /// Standing-body scale (the mockup's `sc`, incl. the unroll overshoot).
  final double standScale;

  /// Breathing multiplier applied to the standing body's height.
  final double breathe;

  /// Eye vertical scale (1 open, 0 shut).
  final double blink;

  /// True while rolling along the path — hides the resting peek face.
  final bool rolling;

  final ElingMood mood;

  double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 120);

    final u = standness;

    // Ground shadow — widens as he stands (scaleX 0.7 → 1.0), per the mockup.
    pgScaleAround(canvas, 0.7 + 0.3 * u, 1, 60, 108, () {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(60, 108), width: 76, height: 8),
        pgFill(const Color(0xFF18231D).withValues(alpha: 0.14)),
      );
    });

    if (mood == ElingMood.hore) _confetti(canvas);

    // Ball (fades out as he stands).
    final ballOpacity = _clamp01(1 - (u - 0.3) / 0.25);
    _withOpacity(canvas, ballOpacity, () {
      pgScaleAround(canvas, 1 - 0.35 * u, 1 - 0.35 * u, 60, 106, () {
        drawElingBall(
          canvas,
          mood,
          rollDegrees: rollDegrees,
          showFace: !rolling,
          blink: blink,
        );
      });
    });

    // Standing body (fades in).
    final standOpacity = _clamp01((u - 0.2) / 0.25);
    _withOpacity(canvas, standOpacity, () {
      pgScaleAround(canvas, standScale, standScale * breathe, 60, 106, () {
        drawElingStand(canvas, mood, blink: blink);
      });
    });

    canvas.restore();
  }

  void _withOpacity(Canvas canvas, double opacity, VoidCallback body) {
    if (opacity <= 0) return;
    if (opacity >= 1) {
      body();
      return;
    }
    canvas.saveLayer(
      null,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    body();
    canvas.restore();
  }

  void _confetti(Canvas canvas) {
    const red = Color(0xFFE5533D);
    const green = Color(0xFF1F8A5B);
    const gold = Color(0xFFF7BE34);
    void bit(double x, double y, double w, double h, Color c, double deg) {
      pgRotate(canvas, deg, x + w / 2, y + h / 2, () {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, w, h), const Radius.circular(1.5)),
          pgFill(c),
        );
      });
    }

    bit(14, 20, 6, 3, red, 30);
    bit(108, 44, 6, 3, green, -20);
    canvas.drawCircle(const Offset(40, 22), 2.5, pgFill(green));
    canvas.drawCircle(const Offset(104, 26), 2.5, pgFill(gold));
    bit(6, 56, 6, 3, gold, -40);
    canvas.drawCircle(const Offset(58, 14), 2.2, pgFill(red));
  }

  @override
  bool shouldRepaint(ElingPainter old) =>
      old.mood != mood ||
      old.standness != standness ||
      old.rollDegrees != rollDegrees ||
      old.standScale != standScale ||
      old.breathe != breathe ||
      old.blink != blink ||
      old.rolling != rolling;
}
