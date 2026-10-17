import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme.dart';
import 'eling_hill_painter.dart' show kElingBase;
import 'eling_motion.dart';

/// One frame of Eling's animation — everything [ElingScene] computes per tick
/// and hands to the painters.
class ElingFrame {
  ElingFrame({
    required this.standness,
    required this.rollDegrees,
    required this.standScale,
    required this.breathe,
    required this.blink,
    required this.rolling,
    required this.elingLen,
    required this.greenLen,
    required this.bubbleOpacity,
    required this.bubbleScale,
  });
  /// Waiting-for-data pose: a still ball at the start dot [startLen], no bubble.
  factory ElingFrame.waiting(double startLen) => ElingFrame(
        standness: 0,
        rollDegrees: 0,
        standScale: 0.55,
        breathe: 1,
        blink: 1,
        rolling: true,
        elingLen: startLen,
        greenLen: startLen,
        bubbleOpacity: 0,
        bubbleScale: 1,
      );

  final double standness, rollDegrees, standScale, breathe, blink;
  final bool rolling;
  final double elingLen, greenLen, bubbleOpacity, bubbleScale;
}

/// Three small floating hearts beside Eling during a tap reaction (DESIGN.md
/// section 7). [tMs] is elapsed milliseconds in whatever controller drives
/// the tap; [anchor] is Eling's resting base point, in the same coordinate
/// space as [s] (px per scene unit).
List<Widget> elingTapHearts({
  required double tMs,
  required Offset anchor,
  required double s,
  double startMs = 250,
  double spanMs = 1050,
  double stepMs = 180,
}) {
  final hearts = <Widget>[];
  for (var i = 0; i < 3; i++) {
    final hp = elingSeg(
        tMs, startMs + i * stepMs, startMs + spanMs + i * stepMs);
    if (hp <= 0 || hp >= 1) continue;
    final opacity = hp < 0.2 ? hp * 5 : 1 - (hp - 0.2) / 0.8;
    final x =
        anchor.dx + 24 + const [0.0, 14.0, 26.0][i] + math.sin(hp * 6 + i) * 4;
    final y = anchor.dy - kElingBase - 4 - hp * 26;
    hearts.add(Positioned(
      left: x * s,
      top: y * s,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + 0.5 * hp,
          child: const Icon(Icons.favorite, size: 18, color: Color(0xFFE5533D)),
        ),
      ),
    ));
  }
  return hearts;
}

/// White rounded speech bubble with a small diamond tail pointing down at Eling.
class ElingSpeechBubble extends StatelessWidget {
  const ElingSpeechBubble({
    super.key,
    required this.text,
    required this.tailLeft,
  });

  final String text;
  final double tailLeft;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          // Wide enough that the tail always sits under the bubble, even for
          // a short line when Eling stands far to the right.
          constraints: BoxConstraints(minWidth: tailLeft + 34),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: FtColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FtColors.line, width: 0.5),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: FtColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: tailLeft),
          child: Transform.translate(
            offset: const Offset(0, -4),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: FtColors.surface,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: FtColors.line, width: 0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
