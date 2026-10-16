import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme.dart';

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
