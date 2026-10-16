import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../widgets/home_formatters.dart';
import 'eling_hill_painter.dart';
import 'eling_mood.dart';
import 'eling_painter.dart';
import 'eling_scene_parts.dart';

/// Per-app-session flags.
class ElingSession {
  ElingSession._();

  /// The entrance (count-up + roll) plays only the first time Beranda opens.
  /// Coming back to the tab shows the final state.
  static bool entrancePlayed = false;

  /// Whether the hero inputs have settled at least once this session. Set on
  /// the first stable frame so later mounts (tab revisits) render instantly
  /// instead of re-waiting for the debounce.
  static bool settledOnce = false;
}

/// The hero scene: the hill, the payday path from the cycle start to the
/// payday house, the date labels, Eling walking to today's spot, and his
/// speech bubble. Owns the entrance, idle and tap animations (DESIGN.md
/// section 7). The big number + sentence live in the parent hero widget.
class ElingScene extends StatefulWidget {
  const ElingScene({
    super.key,
    required this.ready,
    required this.mood,
    required this.perDay,
    required this.daysElapsed,
    required this.cycleLength,
    required this.bubbleText,
    required this.startLabel,
    required this.paydayLabel,
  });

  /// When false the inputs haven't settled yet: Eling waits as a still ball at
  /// the start dot with no bubble. The entrance plays once this flips true.
  final bool ready;

  final ElingMood mood;
  final int perDay;
  final int daysElapsed;
  final int cycleLength;

  /// Resting line — the locked daily insight, else the mood line.
  final String bubbleText;

  /// "30 Sep" (cycle start) and "Gajian 30 Okt" (payday).
  final String startLabel;
  final String paydayLabel;

  @override
  State<ElingScene> createState() => _ElingSceneState();
}

class _ElingSceneState extends State<ElingScene>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _idle;
  late final AnimationController _tap;
  late final TrackGeometry _geo;
  Timer? _tapTimer;
  bool _reduceTapLine = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _geo = TrackGeometry();
    _entrance =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2300));
    _idle = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _tap =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.ready) _maybeStart();
  }

  @override
  void didUpdateWidget(ElingScene old) {
    super.didUpdateWidget(old);
    if (widget.ready && !old.ready) _maybeStart();
  }

  /// Runs once the inputs are ready. Plays the entrance on the session's first
  /// open; otherwise (reduce motion, or already played) the default rest frame
  /// shows the final pose with no animation.
  void _maybeStart() {
    if (_started) return;
    _started = true;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce || ElingSession.entrancePlayed) return;
    ElingSession.entrancePlayed = true;
    _entrance.forward().then((_) {
      if (mounted) _idle.forward();
    });
  }

  @override
  void dispose() {
    _tapTimer?.cancel();
    _entrance.dispose();
    _idle.dispose();
    _tap.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.ready) return;
    FtHaptics.tap();
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _reduceTapLine = true);
      _tapTimer?.cancel();
      _tapTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _reduceTapLine = false);
      });
      return;
    }
    if (_entrance.isAnimating) return;
    _tap.forward(from: 0);
  }

  static double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);
  static double _back(double p) {
    const c = 1.9;
    return 1 + (c + 1) * math.pow(p - 1, 3) + c * math.pow(p - 1, 2);
  }

  @override
  Widget build(BuildContext context) {
    final cycleLength = widget.cycleLength <= 0 ? 1 : widget.cycleLength;
    final todayFraction =
        (widget.daysElapsed / cycleLength).clamp(0.0, 1.0);
    final l0 = _geo.l0;
    final lt = _geo.l0 + (_geo.l1 - _geo.l0) * todayFraction;
    final restRollDeg = ((lt - l0) / kBallRadius) * 180 / math.pi;
    final restStand =
        (widget.mood == ElingMood.senang || widget.mood == ElingMood.hore)
            ? 1.0
            : 0.0;

    final colors = ElingSceneColors(
      hill: Color.alphaBlend(FtColors.clay.withValues(alpha: 0.12), FtColors.hero),
      emptyPath:
          Color.alphaBlend(FtColors.clay.withValues(alpha: 0.30), FtColors.hero),
      filledPath: FtColors.clay,
      dot: FtColors.clay,
      houseBody: FtColors.surface,
      roof: const Color(0xFFE5533D),
      door: FtColors.clay,
    );

    final tapLine = widget.perDay > 0
        ? 'Hihi, geli! Hari ini masih aman, ${compactMoney(widget.perDay)} lagi ya.'
        : 'Hihi, geli! Pelan-pelan dulu ya.';

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final s = w / kSceneW;
          return AnimatedBuilder(
            animation: Listenable.merge([_entrance, _idle, _tap]),
            builder: (context, _) {
              final f = _computeFrame(
                l0: l0,
                lt: lt,
                restStand: restStand,
                restRollDeg: restRollDeg,
              );
              final pt = _geo.pointAt(f.elingLen);
              final restPt = _geo.pointAt(lt);
              final showTapLine = _reduceTapLine || _tap.isAnimating;
              return SizedBox(
                width: w,
                height: kSceneH * s,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ElingHillPainter(
                          geo: _geo,
                          greenLen: f.greenLen,
                          colors: colors,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16 * s,
                      top: 152 * s,
                      child: _label(widget.startLabel),
                    ),
                    Positioned(
                      right: 14 * s,
                      top: 152 * s,
                      child: _label(widget.paydayLabel),
                    ),
                    // Eling.
                    Positioned(
                      left: (pt.dx - kElingHalf) * s,
                      top: (pt.dy - kElingBase) * s,
                      width: kElingSize * s,
                      height: kElingSize * s,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _onTap,
                        child: CustomPaint(
                          painter: ElingPainter(
                            mood: widget.mood,
                            standness: f.standness,
                            rollDegrees: f.rollDegrees,
                            standScale: f.standScale,
                            breathe: f.breathe,
                            blink: f.blink,
                            rolling: f.rolling,
                          ),
                        ),
                      ),
                    ),
                    // Floating hearts (tap).
                    for (var i = 0; i < 3; i++)
                      ..._heart(i, restPt, s),
                    // Speech bubble.
                    Positioned(
                      left: 70 * s,
                      top: 0,
                      width: 248 * s,
                      child: Opacity(
                        opacity: f.bubbleOpacity,
                        child: Transform.scale(
                          scale: f.bubbleScale,
                          alignment: Alignment.bottomCenter,
                          child: ElingSpeechBubble(
                            text: showTapLine ? tapLine : widget.bubbleText,
                            tailLeft: (restPt.dx - 70).clamp(20, 220) * s,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  ElingFrame _computeFrame({
    required double l0,
    required double lt,
    required double restStand,
    required double restRollDeg,
  }) {
    // Waiting for the data to settle: a still ball at the start dot, no bubble.
    if (!widget.ready) return ElingFrame.waiting(l0);

    var standness = restStand;
    var rollDegrees = restRollDeg;
    var standScale = 0.55 + 0.45 * restStand;
    var breathe = 1.0;
    var blink = 1.0;
    var rolling = false;
    var elingLen = lt;
    var greenLen = lt;
    var bubbleOpacity = 1.0;
    var bubbleScale = 1.0;

    final ev = _entrance.value;
    if (ev > 0 && ev < 1) {
      final t = ev * 2300;
      final pw = _seg(t, 0, 1500);
      final eased = 1 - (1 - pw) * (1 - pw);
      elingLen = l0 + (lt - l0) * eased;
      greenLen = elingLen;
      rollDegrees = ((elingLen - l0) / kBallRadius) * 180 / math.pi;
      rolling = t < 1500;
      if (restStand == 1) {
        final up = _seg(t, 1500, 1850);
        standness = up;
        standScale = 0.55 + 0.45 * (up > 0 && up < 1 ? _back(up) : up);
      } else {
        standness = 0;
        standScale = 0.55;
      }
      final bp = _seg(t, 1850, 2200);
      bubbleOpacity = bp > 0 ? 1.0 : 0.0;
      bubbleScale = bp > 0 ? 0.6 + 0.4 * _back(bp) : 0.6;
    }

    final iv = _idle.value;
    if (iv > 0 && iv < 1) {
      final ti = iv * 10000;
      if (restStand == 1) breathe = 1 + 0.022 * math.sin(ti / 420);
      double blinkAt(double a) {
        final b = _seg(ti, a, a + 140);
        return (b > 0 && b < 1) ? 1 - 0.9 * math.sin(math.pi * b) : 1;
      }

      blink = math.min(blinkAt(2750), blinkAt(6000));
    }

    if (_tap.isAnimating) {
      final tt = _tap.value * 1500;
      if (restStand == 1) {
        double u;
        if (tt < 150) {
          u = 1 - _seg(tt, 0, 150);
        } else if (tt < 450) {
          u = 0;
        } else if (tt < 800) {
          u = _seg(tt, 450, 800);
        } else {
          u = 1;
        }
        standness = u;
        final up = (tt >= 450 && tt < 800) ? _seg(tt, 450, 800) : null;
        standScale = 0.55 + 0.45 * (up != null ? _back(up) : u);
        rolling = tt < 800;
      } else {
        standness = 0;
        standScale = 0.55;
      }
      final wob = _seg(tt, 150, 600);
      if (wob > 0 && wob < 1) {
        rollDegrees += math.sin(wob * math.pi * 5) * 14 * (1 - wob);
      }
      elingLen = lt;
      greenLen = lt;
    }

    return ElingFrame(
      standness: standness,
      rollDegrees: rollDegrees,
      standScale: standScale,
      breathe: breathe,
      blink: blink,
      rolling: rolling,
      elingLen: elingLen,
      greenLen: greenLen,
      bubbleOpacity: bubbleOpacity,
      bubbleScale: bubbleScale,
    );
  }

  List<Widget> _heart(int i, Offset restPt, double s) {
    if (!_tap.isAnimating) return const [];
    final tt = _tap.value * 1500;
    final hp = _seg(tt, 250 + i * 180.0, 1300 + i * 180.0);
    if (hp <= 0 || hp >= 1) return const [];
    final opacity = hp < 0.2 ? hp * 5 : 1 - (hp - 0.2) / 0.8;
    // Beside Eling, to the right and floating up — clear of the bubble.
    final x =
        restPt.dx + 24 + const [0.0, 14.0, 26.0][i] + math.sin(hp * 6 + i) * 4;
    final y = restPt.dy - kElingBase - 4 - hp * 26;
    return [
      Positioned(
        left: x * s,
        top: y * s,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.6 + 0.5 * hp,
            child: const Icon(Icons.favorite,
                size: 18, color: Color(0xFFE5533D)),
          ),
        ),
      ),
    ];
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: FtColors.ink2,
        ),
      );
}
