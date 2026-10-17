import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../home/eling/eling_hill_painter.dart';
import '../../home/eling/eling_mood.dart';
import '../../home/eling/eling_painter.dart';
import '../../home/eling/eling_scene_parts.dart';
import '../../home/widgets/home_formatters.dart';
import '../goal.dart';

/// One frame of [GoalHillStack]'s animation, computed by
/// `_GoalProgressHeroState._computeFrame`.
class GoalFrame {
  GoalFrame({
    required this.standness,
    required this.rollDegrees,
    required this.standScale,
    required this.breathe,
    required this.blink,
    required this.rolling,
    required this.pFraction,
    required this.displayedPercent,
    required this.bubbleOpacity,
    required this.bubbleScale,
    required this.ringOpacity,
    required this.ringExtra,
  });

  final double standness, rollDegrees, standScale, breathe, blink;
  final bool rolling;
  final double pFraction;
  final int displayedPercent;
  final double bubbleOpacity, bubbleScale, ringOpacity, ringExtra;
}

/// The hill, path, 50% marker, end icon, Eling and speech bubble for
/// [GoalProgressHero] — a pure presentational Stack driven by a
/// pre-computed [GoalFrame], so the state widget's `build` stays short.
class GoalHillStack extends StatelessWidget {
  const GoalHillStack({
    super.key,
    required this.geo,
    required this.colors,
    required this.goal,
    required this.mood,
    required this.frame,
    required this.w,
    required this.s,
    required this.restPt,
    required this.bubbleText,
    required this.tapHeartsMs,
    required this.onTapEling,
  });

  final TrackGeometry geo;
  final ElingSceneColors colors;
  final Goal goal;
  final ElingMood mood;
  final GoalFrame frame;
  final double w, s;

  /// Eling's settled (non-animating) position — the bubble tail and tap
  /// hearts anchor here, not to the currently-animating position.
  final Offset restPt;
  final String bubbleText;

  /// Elapsed ms in the tap controller, or null when it isn't animating.
  final double? tapHeartsMs;
  final VoidCallback onTapEling;

  @override
  Widget build(BuildContext context) {
    final accent = colors.filledPath;
    final greenLen = geo.l0 + (geo.l1 - geo.l0) * frame.pFraction;
    final pt = geo.pointAt(greenLen);
    final markerPt = geo.pointAt(geo.l0 + (geo.l1 - geo.l0) * 0.5);

    return SizedBox(
      width: w,
      height: kSceneH * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: ElingHillPainter(
                geo: geo,
                greenLen: greenLen,
                colors: colors,
                drawHouse: false,
              ),
            ),
          ),
          Positioned(left: 16 * s, top: 152 * s, child: _edgeLabel('Rp0')),
          Positioned(
            right: 14 * s,
            top: 152 * s,
            child: _edgeLabel(compactMoney(goal.target)),
          ),
          // 50% milestone marker + its one-shot gold ring.
          Positioned(
            left: (markerPt.dx - 9) * s,
            top: (markerPt.dy - 9) * s,
            width: 18 * s,
            height: 18 * s,
            child: CustomPaint(
              painter: MilestonePainter(
                filled: frame.pFraction >= 0.5,
                accent: accent,
                surface: FtColors.surface,
                ringOpacity: frame.ringOpacity,
                ringExtra: frame.ringExtra,
              ),
            ),
          ),
          // End marker: a white circle with the goal icon.
          Positioned(
            left: (geo.p1.dx - 17) * s,
            top: (geo.p1.dy - 14 - 17) * s,
            width: 34 * s,
            height: 34 * s,
            child: Container(
              decoration: BoxDecoration(
                  color: goalEndCircleColor(accent: accent, hero: FtColors.hero),
                  shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(goalIconFor(goal.icon), size: 18 * s, color: accent),
            ),
          ),
          // Eling.
          Positioned(
            // Kept inside the scene so his nose isn't cut off at 100%.
            left: math.min(pt.dx - kElingHalf, kSceneW - kElingSize - 2) * s,
            top: (pt.dy - kElingBase) * s,
            width: kElingSize * s,
            height: kElingSize * s,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapEling,
              child: CustomPaint(
                painter: ElingPainter(
                  mood: mood,
                  standness: frame.standness,
                  rollDegrees: frame.rollDegrees,
                  standScale: frame.standScale,
                  breathe: frame.breathe,
                  blink: frame.blink,
                  rolling: frame.rolling,
                ),
              ),
            ),
          ),
          if (tapHeartsMs != null)
            ...elingTapHearts(tMs: tapHeartsMs!, anchor: restPt, s: s),
          Positioned(
            left: 20 * s,
            top: 0,
            width: 282 * s,
            child: Opacity(
              opacity: frame.bubbleOpacity,
              child: Transform.scale(
                scale: frame.bubbleScale,
                alignment: Alignment.bottomCenter,
                child: ElingSpeechBubble(
                  text: bubbleText,
                  tailLeft: (restPt.dx - 20).clamp(20, 240) * s,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _edgeLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: FtColors.onHero,
        ),
      );
}

/// Fill for the goal's end circle: white, or a darker hero tone, whichever
/// makes the [accent] icon stand out more. `FtColors.surface` failed in dark
/// themes whose hero stays light (Laut): a navy icon on a near-black circle.
Color goalEndCircleColor({required Color accent, required Color hero}) {
  double ratio(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
  }

  const light = Color(0xFFFFFFFF);
  final dark = Color.lerp(hero, const Color(0xFF000000), 0.45)!;
  return ratio(accent, light) >= ratio(accent, dark) ? light : dark;
}

/// The 50% progress marker: a hollow ring until progress passes it, then
/// filled accent, plus a gold ring that grows and fades once when Eling
/// passes it during a roll.
class MilestonePainter extends CustomPainter {
  MilestonePainter({
    required this.filled,
    required this.accent,
    required this.surface,
    required this.ringOpacity,
    required this.ringExtra,
  });

  final bool filled;
  final Color accent, surface;
  final double ringOpacity, ringExtra;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const r = 5.0;
    canvas.drawCircle(center, r, Paint()..color = filled ? accent : surface);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accent,
    );
    if (ringOpacity > 0) {
      canvas.drawCircle(
        center,
        r + ringExtra,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFF7BE34).withValues(alpha: ringOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(MilestonePainter old) =>
      old.filled != filled ||
      old.accent != accent ||
      old.ringOpacity != ringOpacity ||
      old.ringExtra != ringExtra;
}
