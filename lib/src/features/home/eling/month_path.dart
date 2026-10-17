import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/month_path.dart';
import '../../../theme.dart';
import 'eling_hill_painter.dart' show kElingBase, kElingHalf;
import 'eling_mood.dart';
import 'eling_motion.dart';
import 'eling_painter.dart';
import 'eling_scene.dart' show ElingSession;
import 'month_path_track.dart';

export 'month_path_track.dart' show MonthPathMini;

/// Animated month path with a small standing Eling (DESIGN.md section 6,
/// item 2): entrance rolls him to the last paid dot once per screen per
/// session; a later `monthsPaid` bump rolls him one dot forward with hearts
/// and a short "Mantap!" bubble.
class MonthPathEling extends StatefulWidget {
  const MonthPathEling({
    super.key,
    required this.entranceId,
    required this.monthsTotal,
    required this.monthsPaid,
    required this.startedAt,
    this.showEling = true,
  });

  /// Unique per tile (e.g. the obligation/installment id) — entrance plays
  /// once per id per app session, like [ElingSession.goalsEntered].
  final String entranceId;
  final int monthsTotal;
  final int monthsPaid;
  final DateTime startedAt;

  /// False for completed (dimmed) tiles: shows the path full with no Eling
  /// and no animation.
  final bool showEling;

  @override
  State<MonthPathEling> createState() => _MonthPathElingState();
}

class _MonthPathElingState extends State<MonthPathEling>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _bump;
  late final AnimationController _bubble;
  Timer? _reduceBubbleTimer;
  bool _reduceShowBubble = false;
  bool _started = false;
  int _restingPaid = 0;

  int get _total => widget.monthsTotal < 1 ? 1 : widget.monthsTotal;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1350));
    _bump = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _bubble = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final already = ElingSession.monthPathsEntered.contains(widget.entranceId);
    if (!widget.showEling || reduce || already) {
      _restingPaid = widget.monthsPaid;
      return;
    }
    ElingSession.monthPathsEntered.add(widget.entranceId);
    _entrance.forward().then((_) {
      if (mounted) setState(() => _restingPaid = widget.monthsPaid);
    });
  }

  @override
  void didUpdateWidget(MonthPathEling old) {
    super.didUpdateWidget(old);
    if (!_started || old.monthsPaid == widget.monthsPaid) return;
    if (!widget.showEling) {
      setState(() => _restingPaid = widget.monthsPaid);
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _restingPaid = widget.monthsPaid;
        _reduceShowBubble = true;
      });
      _reduceBubbleTimer?.cancel();
      _reduceBubbleTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _reduceShowBubble = false);
      });
      return;
    }
    _bump.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _restingPaid = widget.monthsPaid);
      _bubble.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _reduceBubbleTimer?.cancel();
    _entrance.dispose();
    _bump.dispose();
    _bubble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = FtColors.clay;
    final light =
        Color.alphaBlend(accent.withValues(alpha: 0.22), FtColors.surface);
    final endMonth = monthPathEndMonth(widget.startedAt, widget.monthsTotal);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, c) {
          final geo = MonthGeo(c.maxWidth);
          return AnimatedBuilder(
            animation: Listenable.merge([_entrance, _bump, _bubble]),
            builder: (context, _) {
              final f = _frame();
              final pt = geo.pointAt(f.fraction);
              final restPt = geo.pointAt(_restingPaid / _total);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: c.maxWidth,
                    height: widget.showEling ? 70 : 26,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: 0,
                          top: 22,
                          right: 0,
                          child: CustomPaint(
                            size: Size(c.maxWidth, 48),
                            painter: MonthTrackPainter(
                              geo: geo,
                              monthsTotal: _total,
                              paidFraction: f.fraction,
                              accent: accent,
                              light: light,
                              surface: FtColors.surface,
                            ),
                          ),
                        ),
                        Positioned(
                          left: geo.x1 - 7,
                          top: 22 + geo.pointAt(1).dy - 22,
                          child: Icon(Icons.flag, size: 16, color: accent),
                        ),
                        if (widget.showEling) ...[
                          Positioned(
                            left: pt.dx - kElingHalf * (46 / 84),
                            top: 22 + pt.dy - kElingBase * (46 / 84),
                            width: 46,
                            height: 46,
                            child: CustomPaint(
                              painter: ElingPainter(
                                mood: ElingMood.senang,
                                standness: f.standness,
                                rollDegrees: f.rollDegrees,
                                standScale: f.standScale,
                                breathe: 1,
                                blink: 1,
                                rolling: f.rolling,
                              ),
                            ),
                          ),
                          if (_bubble.isAnimating)
                            ..._hearts(restPt, _bubble.value * 1500),
                        ],
                        if (widget.showEling &&
                            (f.bubbleOpacity > 0 || _reduceShowBubble))
                          // Beside Eling, never on top of him: to the right
                          // of his nose, or to his left near the end.
                          Builder(builder: (context) {
                            final room = c.maxWidth - (restPt.dx + 26);
                            final onRight = room >= _kMiniBubbleW;
                            return Positioned(
                              left: onRight
                                  ? restPt.dx + 26
                                  : math.max(0.0,
                                      restPt.dx - 30 - _kMiniBubbleW),
                              top: 2,
                              child: Opacity(
                                opacity:
                                    _reduceShowBubble ? 1 : f.bubbleOpacity,
                                child: Transform.scale(
                                  scale: _reduceShowBubble
                                      ? 1
                                      : f.bubbleScale,
                                  alignment: onRight
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: _MiniBubble(
                                    text: monthPathBumpLine(
                                        _total - widget.monthsPaid),
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _monthLabel(widget.startedAt),
                        style: TextStyle(color: FtColors.ink3, fontSize: 11),
                      ),
                      Text(
                        'Lunas ${_monthLabel(endMonth)}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Three small hearts floating up beside the resting dot — real pixel
  /// coordinates (unlike [elingTapHearts], which works in scene units).
  List<Widget> _hearts(Offset restPt, double tMs) {
    final hearts = <Widget>[];
    for (var i = 0; i < 3; i++) {
      final hp = elingSeg(tMs, i * 140.0, 900 + i * 140.0);
      if (hp <= 0 || hp >= 1) continue;
      final opacity = hp < 0.2 ? hp * 5 : 1 - (hp - 0.2) / 0.8;
      final x = restPt.dx + 16 + const [0.0, 10.0, 18.0][i] +
          math.sin(hp * 6 + i) * 3;
      final y = 22 + restPt.dy - 30 - hp * 18;
      hearts.add(Positioned(
        left: x,
        top: y,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.6 + 0.5 * hp,
            child: const Icon(Icons.favorite, size: 13, color: Color(0xFFE5533D)),
          ),
        ),
      ));
    }
    return hearts;
  }

  _MonthFrame _frame() {
    var standness = 1.0;
    var rollDegrees = 0.0;
    var standScale = 1.0;
    var rolling = false;
    var fraction = _restingPaid / _total;
    var bubbleOpacity = 0.0;
    var bubbleScale = 0.6;

    if (_entrance.isAnimating) {
      final t = _entrance.value * 1350;
      final target = widget.monthsPaid / _total;
      final posP = Curves.easeOutCubic.transform(elingSeg(t, 0, 1000));
      fraction = target * posP;
      rolling = t < 1000;
      standness = t < 1000 ? 0 : elingSeg(t, 1000, 1350);
      standScale =
          (standness > 0 && standness < 1) ? elingBack(standness) : standness;
      rollDegrees = fraction * _total * 60;
    } else if (_bump.isAnimating) {
      final t = _bump.value * 1100;
      final from = _restingPaid / _total;
      final to = widget.monthsPaid / _total;
      final rollP = Curves.easeOutCubic.transform(elingSeg(t, 150, 750));
      fraction = from + (to - from) * rollP;
      rolling = t < 750;
      if (t < 150) {
        standness = 1 - elingSeg(t, 0, 150);
      } else if (t < 750) {
        standness = 0;
      } else {
        standness = elingSeg(t, 750, 1100);
      }
      standScale =
          (standness > 0 && standness < 1) ? elingBack(standness) : standness;
      rollDegrees = (to - from) * _total * 60;
    } else if (_bubble.isAnimating) {
      final t = _bubble.value * 1500;
      final bp = elingSeg(t, 0, 250);
      final fade = elingSeg(t, 1250, 1500);
      bubbleOpacity = bp > 0 ? 1 - fade : 0;
      bubbleScale = bp > 0 ? 0.6 + 0.4 * elingBack(bp) : 0.6;
    }
    return _MonthFrame(
      standness: standness,
      rollDegrees: rollDegrees,
      standScale: standScale,
      rolling: rolling,
      fraction: fraction,
      bubbleOpacity: bubbleOpacity,
      bubbleScale: bubbleScale,
    );
  }
}

class _MonthFrame {
  _MonthFrame({
    required this.standness,
    required this.rollDegrees,
    required this.standScale,
    required this.rolling,
    required this.fraction,
    required this.bubbleOpacity,
    required this.bubbleScale,
  });
  final double standness, rollDegrees, standScale, fraction;
  final bool rolling;
  final double bubbleOpacity, bubbleScale;
}

String _monthLabel(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];
  return '${months[d.month - 1]} ${d.year}';
}

/// One-line width of "Mantap! Tinggal 12 bulan lagi." at 12px, plus padding.
const double _kMiniBubbleW = 178;

/// Small light-hero bubble used by the month path's "Mantap!" line — plainer
/// than [ElingSpeechBubble] (no tail) since it floats beside a 46px Eling.
class _MiniBubble extends StatelessWidget {
  const _MiniBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kMiniBubbleW,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: FtColors.hero,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: FtColors.onHero),
      ),
    );
  }
}
