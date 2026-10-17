import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../../home/eling/eling_hill_painter.dart';
import '../../home/eling/eling_mood.dart';
import '../../home/eling/eling_motion.dart';
import '../../home/eling/eling_scene.dart' show ElingSession;
import '../../home/widgets/home_formatters.dart';
import '../goal.dart';
import 'goal_bubble.dart';
import 'goal_progress_scene.dart';

/// The goal-detail hero (DESIGN.md section 6, "Tujuan"): the percent, the
/// hill and payday-style path from Rp0 to the target, Eling rolling to the
/// current progress, a 50% milestone marker, and his speech bubble. Mirrors
/// `ElingScene`'s motion rules (entrance once per goal per session, replay on
/// progress change, tap reaction, reduce motion) using the same drawing
/// primitives. The Stack itself lives in [GoalHillStack]; this widget owns
/// the animation timelines.
class GoalProgressHero extends StatefulWidget {
  const GoalProgressHero({super.key, required this.goal});
  final Goal goal;

  @override
  State<GoalProgressHero> createState() => _GoalProgressHeroState();
}

class _GoalProgressHeroState extends State<GoalProgressHero>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _update;
  late final AnimationController _tap;
  late final AnimationController _idle;
  late final TrackGeometry _geo;
  Timer? _tapTimer;
  bool _reduceTapLine = false;
  bool _started = false;

  double _restingFraction = 0;
  double _updateFromFraction = 0;
  double _lastFractionSeen = 0;
  double? _ringStartMs;

  static double _fractionOf(Goal g) =>
      g.target <= 0 ? 0.0 : (g.current / g.target).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _geo = TrackGeometry();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));
    _update = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1750));
    _tap = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _idle =
        AnimationController(vsync: this, duration: const Duration(seconds: 10));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  void _maybeStart() {
    if (_started) return;
    _started = true;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final already = ElingSession.goalsEntered.contains(widget.goal.id);
    if (reduce || already) {
      _restingFraction = _fractionOf(widget.goal);
      return;
    }
    ElingSession.goalsEntered.add(widget.goal.id);
    _lastFractionSeen = 0;
    _ringStartMs = null;
    _entrance.forward().then((_) {
      if (!mounted) return;
      setState(() => _restingFraction = _fractionOf(widget.goal));
      _idle.forward();
    });
  }

  @override
  void didUpdateWidget(GoalProgressHero old) {
    super.didUpdateWidget(old);
    if (!_started || old.goal.current == widget.goal.current) return;
    final newFraction = _fractionOf(widget.goal);
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _restingFraction = newFraction);
      return;
    }
    _updateFromFraction = _restingFraction;
    _lastFractionSeen = _restingFraction;
    _ringStartMs = null;
    _update.forward(from: 0).then((_) {
      if (mounted) setState(() => _restingFraction = newFraction);
    });
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _entrance.dispose();
    _update.dispose();
    _tap.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _onTap() {
    FtHaptics.tap();
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _reduceTapLine = true);
      _tapTimer?.cancel();
      _tapTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _reduceTapLine = false);
      });
      return;
    }
    if (_entrance.isAnimating || _update.isAnimating) return;
    _tap.forward(from: 0);
  }

  void _checkRingCrossing(double fractionNow, double threshold, double tMs) {
    if (_ringStartMs == null &&
        _lastFractionSeen < threshold &&
        fractionNow >= threshold) {
      _ringStartMs = tMs;
    }
    _lastFractionSeen = fractionNow;
  }

  double? _ringProgress(double tMs) {
    final start = _ringStartMs;
    if (start == null) return null;
    return elingSeg(tMs, start, start + 600);
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final colors = ElingSceneColors.fromTheme();
    final bubble = goalBubbleCopy(
      current: goal.current,
      target: goal.target,
      monthlyContrib: goal.monthlyContrib,
    );
    final tapLine = 'Hihi, geli! ${bubble.line1}';
    final mood = goal.isComplete ? ElingMood.hore : ElingMood.senang;

    return Container(
      width: double.infinity,
      color: FtColors.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Text(
              'Tercapai',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: FtColors.onHero.withValues(alpha: 0.65),
              ),
            ),
          ),
          RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final s = w / kSceneW;
                return AnimatedBuilder(
                  animation:
                      Listenable.merge([_entrance, _update, _tap, _idle]),
                  builder: (context, _) {
                    final f = _computeFrame();
                    final restPt = _geo.pointAt(
                        _geo.l0 + (_geo.l1 - _geo.l0) * _restingFraction);
                    final showTapLine = _reduceTapLine || _tap.isAnimating;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                          child: _percentText(f.displayedPercent),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 6, 24, 8),
                          child: Text(
                            '${compactMoney(goal.current)} dari ${compactMoney(goal.target)}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: FtColors.onHero.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                        GoalHillStack(
                          geo: _geo,
                          colors: colors,
                          goal: goal,
                          mood: mood,
                          frame: f,
                          w: w,
                          s: s,
                          restPt: restPt,
                          bubbleText: showTapLine ? tapLine : bubble.text,
                          tapHeartsMs:
                              _tap.isAnimating ? _tap.value * 1500 : null,
                          onTapEling: _onTap,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  GoalFrame _computeFrame() {
    double rollDegFor(double fromFraction, double toFraction) {
      final dLen = (toFraction - fromFraction) * (_geo.l1 - _geo.l0);
      return dLen / kBallRadius * 180 / math.pi;
    }

    var standness = 1.0;
    var rollDegrees = rollDegFor(0, _restingFraction);
    var standScale = 1.0;
    var breathe = 1.0;
    var blink = 1.0;
    var rolling = false;
    var pFraction = _restingFraction;
    var bubbleOpacity = 1.0;
    var bubbleScale = 1.0;
    var ringOpacity = 0.0;
    var ringExtra = 0.0;

    if (_entrance.isAnimating) {
      final t = _entrance.value * 2500;
      final target = _fractionOf(widget.goal);
      final posP = Curves.easeOutCubic.transform(elingSeg(t, 300, 1800));
      pFraction = target * posP;
      rollDegrees = rollDegFor(0, pFraction);
      rolling = t < 1800;
      standness = t < 1800 ? 0 : elingSeg(t, 1800, 2150);
      standScale =
          (standness > 0 && standness < 1) ? elingBack(standness) : standness;
      final bp = elingSeg(t, 2150, 2500);
      bubbleOpacity = bp > 0 ? 1 : 0;
      bubbleScale = bp > 0 ? 0.6 + 0.4 * elingBack(bp) : 0.6;
      _checkRingCrossing(pFraction, target >= 0.5 ? 0.5 : 2, t);
    } else if (_update.isAnimating) {
      final t = _update.value * 1750;
      final from = _updateFromFraction;
      final to = _fractionOf(widget.goal);
      final rollP = Curves.easeOutCubic.transform(elingSeg(t, 150, 1050));
      pFraction = from + (to - from) * rollP;
      rollDegrees = rollDegFor(from, pFraction);
      rolling = t < 1050;
      if (t < 150) {
        standness = 1 - elingSeg(t, 0, 150);
      } else if (t < 1050) {
        standness = 0;
      } else {
        standness = elingSeg(t, 1050, 1400);
      }
      standScale =
          (standness > 0 && standness < 1) ? elingBack(standness) : standness;
      final bp = elingSeg(t, 1400, 1750);
      bubbleOpacity = bp > 0 ? 1 : 0;
      bubbleScale = bp > 0 ? 0.6 + 0.4 * elingBack(bp) : 0.6;
      _checkRingCrossing(pFraction, 0.5, t);
    } else if (_tap.isAnimating) {
      final tt = _tap.value * 1500;
      double u;
      if (tt < 150) {
        u = 1 - elingSeg(tt, 0, 150);
      } else if (tt < 450) {
        u = 0;
      } else if (tt < 800) {
        u = elingSeg(tt, 450, 800);
      } else {
        u = 1;
      }
      standness = u;
      final up = (tt >= 450 && tt < 800) ? elingSeg(tt, 450, 800) : null;
      standScale = up != null ? elingBack(up) : u;
      rolling = tt < 800;
      final wob = elingSeg(tt, 150, 600);
      if (wob > 0 && wob < 1) {
        rollDegrees += math.sin(wob * math.pi * 5) * 14 * (1 - wob);
      }
      pFraction = _restingFraction;
    } else {
      final iv = _idle.value;
      if (iv > 0 && iv < 1) {
        final ti = iv * 10000;
        breathe = 1 + 0.022 * math.sin(ti / 420);
        double blinkAt(double a) {
          final b = elingSeg(ti, a, a + 140);
          return (b > 0 && b < 1) ? 1 - 0.9 * math.sin(math.pi * b) : 1;
        }

        blink = math.min(blinkAt(2750), blinkAt(6000));
      }
    }

    final rp = _ringProgress(
      _entrance.isAnimating
          ? _entrance.value * 2500
          : (_update.isAnimating ? _update.value * 1750 : -1),
    );
    if (rp != null) {
      ringOpacity = rp > 0 && rp < 1 ? 1 - rp : 0;
      ringExtra = rp * 14;
    }

    return GoalFrame(
      standness: standness,
      rollDegrees: rollDegrees,
      standScale: standScale,
      breathe: breathe,
      blink: blink,
      rolling: rolling,
      pFraction: pFraction,
      displayedPercent: (pFraction * 100).round(),
      bubbleOpacity: bubbleOpacity,
      bubbleScale: bubbleScale,
      ringOpacity: ringOpacity,
      ringExtra: ringExtra,
    );
  }

  Widget _percentText(int pct) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(
          text: '$pct',
          style: GoogleFonts.fredoka(
            fontSize: 58,
            height: 1,
            letterSpacing: -0.5,
            fontWeight: FontWeight.w600,
            color: FtColors.onHero,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        TextSpan(
          text: '%',
          style: GoogleFonts.fredoka(
            fontSize: 30,
            fontWeight: FontWeight.w500,
            color: FtColors.onHero,
          ),
        ),
      ]),
    );
  }
}
