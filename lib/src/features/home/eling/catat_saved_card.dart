import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/catat_card.dart';
import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../widgets/home_formatters.dart';
import 'eling_mood.dart';
import 'eling_motion.dart';
import 'eling_painter.dart';

/// Small card shown for ~2s above the bottom nav after saving a new single
/// expense (DESIGN.md section 6, item 3), in place of the generic
/// `FtCelebrate` "Tersimpan" — it shows what that save did to the category's
/// budget. Tap dismisses it; it never blocks taps on the rest of the screen.
class CatatSavedCard {
  CatatSavedCard._();

  static void show(
    BuildContext context, {
    required String categoryLabel,
    required String amountLabel,
    required CatatCardAmounts amounts,
    required int budget,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _CatatSavedCard(
        categoryLabel: categoryLabel,
        amountLabel: amountLabel,
        amounts: amounts,
        budget: budget,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }
}

class _CatatSavedCard extends StatefulWidget {
  const _CatatSavedCard({
    required this.categoryLabel,
    required this.amountLabel,
    required this.amounts,
    required this.budget,
    required this.onDone,
  });

  final String categoryLabel;
  final String amountLabel;
  final CatatCardAmounts amounts;
  final int budget;
  final VoidCallback onDone;

  @override
  State<_CatatSavedCard> createState() => _CatatSavedCardState();
}

class _CatatSavedCardState extends State<_CatatSavedCard>
    with TickerProviderStateMixin {
  late final AnimationController _slide;
  late final AnimationController _count;
  Timer? _holdTimer;
  bool _started = false;
  bool _reduce = false;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    // Runs from the moment the card appears: the first 350ms are the slide-in,
    // then the 1200ms count. One timeline, so the count never waits on a
    // future callback from the slide (that callback did not fire reliably).
    _count = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350 + 1200));
    if (widget.amounts.over) {
      FtHaptics.warning();
    } else {
      FtHaptics.success();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduce = MediaQuery.disableAnimationsOf(context);
    if (_reduce) {
      _slide.value = 1;
      _count.value = 1;
    } else {
      _slide.forward();
      _count.forward();
    }
    // Count ends at 1550ms; keep the final number readable for ~1s more.
    _holdTimer = Timer(
        Duration(milliseconds: _reduce ? 2000 : 2600), _dismiss);
  }

  void _dismiss() {
    _holdTimer?.cancel();
    if (_reduce) {
      widget.onDone();
      return;
    }
    _slide.reverse().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _slide.dispose();
    _count.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 14,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 70),
        child: AnimatedBuilder(
          animation: Listenable.merge([_slide, _count]),
          // The body is built inside the builder: it depends on `_count`, so
          // passing it as the cached `child` froze the number at its start.
          builder: (context, _) {
            final t = _reduce
                ? 1.0
                : Curves.easeOutBack.transform(_slide.value);
            return Opacity(
              opacity: _reduce ? 1 : _slide.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 60),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismiss,
                  child: _CatatCardBody(
                    categoryLabel: widget.categoryLabel,
                    amountLabel: widget.amountLabel,
                    amounts: widget.amounts,
                    budget: widget.budget,
                    countMs: _reduce
                        ? 1200
                        : math.max(0, _count.value * (350 + 1200) - 350),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CatatCardBody extends StatelessWidget {
  const _CatatCardBody({
    required this.categoryLabel,
    required this.amountLabel,
    required this.amounts,
    required this.budget,
    required this.countMs,
  });

  final String categoryLabel;
  final String amountLabel;
  final CatatCardAmounts amounts;
  final int budget;
  final double countMs;

  @override
  Widget build(BuildContext context) {
    final over = amounts.over;
    final cp = Curves.easeOutCubic.transform(elingSeg(countMs, 0, 900));
    final value = amounts.oldValue + (amounts.newValue - amounts.oldValue) * cp;

    var standness = over ? 0.0 : 1.0;
    var hop = 0.0;
    var wobble = 0.0;
    if (!over) {
      standness = elingSeg(countMs, 650, 950);
      final hp = elingSeg(countMs, 900, 1200);
      hop = hp > 0 && hp < 1 ? math.sin(math.pi * hp) * 8 : 0;
    } else {
      final wp = elingSeg(countMs, 900, 1200);
      wobble = wp > 0 && wp < 1 ? math.sin(wp * math.pi * 4) * 10 * (1 - wp) : 0;
    }
    final standScale =
        (standness > 0 && standness < 1) ? elingBack(standness) : standness;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 14, 16, 14),
        decoration: BoxDecoration(
          color: FtColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FtColors.line, width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Transform.translate(
                offset: Offset(0, -hop),
                child: Transform.rotate(
                  angle: wobble * math.pi / 180,
                  child: CustomPaint(
                    painter: ElingPainter(
                      mood: over ? ElingMood.ngirit : ElingMood.senang,
                      standness: standness,
                      rollDegrees: 0,
                      standScale: standScale,
                      breathe: 1,
                      blink: 1,
                      rolling: false,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$categoryLabel $amountLabel tersimpan',
                    style: TextStyle(color: FtColors.ink3, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    over ? '$categoryLabel lewat' : 'Sisa $categoryLabel',
                    style: TextStyle(
                      color: FtColors.ink2,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    compactMoney(value.round()),
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: over ? FtColors.danger : FtColors.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (!over && budget > 0) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (value / budget).clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: FtColors.line,
                        valueColor: AlwaysStoppedAnimation(FtColors.clay),
                      ),
                    ),
                  ],
                  if (over) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Pelan-pelan dulu ya.',
                      style: TextStyle(color: FtColors.ink2, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
