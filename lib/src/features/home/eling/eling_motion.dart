/// Shared pure easing math for every Eling sequence (hero scene, goal scene,
/// month path, after-Catat card). Keeping it in one place means the roll/
/// stand/bubble timelines feel the same everywhere without copying the
/// formulas into each widget.
library;

import 'dart:math' as math;

/// Clamped progress of `t` between `a` and `b`, in `[0, 1]`.
double elingSeg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);

/// Overshoot-then-settle easing used for the stand-up pop and the bubble
/// pop-in (DESIGN.md section 7).
double elingBack(double p) {
  const c = 1.9;
  return 1 + (c + 1) * math.pow(p - 1, 3) + c * math.pow(p - 1, 2);
}
