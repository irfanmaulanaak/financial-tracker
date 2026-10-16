import 'package:flutter/material.dart';

import '../theme.dart';

Color ftProgressColor(num value, num max, {bool dangerWhenOver = false}) {
  if (dangerWhenOver && max > 0 && value > max) {
    return FtColors.danger;
  }
  final ratio = max <= 0 ? 0.0 : value / max;
  return ratio >= 0.8 ? FtColors.ink : FtColors.ink.withValues(alpha: 0.7);
}

class FtProgressBar extends StatelessWidget {
  const FtProgressBar({
    super.key,
    required this.value,
    required this.max,
    required this.color,
    this.height = 4,
    this.trackColor,
    this.overflowColor,
    this.animationDuration = const Duration(milliseconds: 360),
  });

  final num value;
  final num max;
  final Color color;
  final double height;
  final Color? trackColor;

  /// When `value > max`, the visible track is split: filled portion = base color,
  /// remaining = overflowColor (typically `FtColors.danger`). Matches design's
  /// `Bar overflowColor={theme.danger}` from `screens-home.jsx`.
  final Color? overflowColor;

  /// How long to animate when [value] or [max] changes. Set to `Duration.zero`
  /// to disable. Honors `MediaQuery.disableAnimations` automatically.
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    if (max <= 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: 0,
          minHeight: height,
          backgroundColor: trackColor ?? FtColors.line,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }
    final raw = (value / max).toDouble();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : animationDuration;

    final over = overflowColor != null && raw > 1.0;
    if (!over) {
      final target = raw.clamp(0.0, 1.0);
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: target, end: target),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (_, v, _) {
            return LinearProgressIndicator(
              value: v,
              minHeight: height,
              backgroundColor: trackColor ?? FtColors.line,
              valueColor: AlwaysStoppedAnimation(color),
            );
          },
        ),
      );
    }
    final overFraction = ((raw - 1.0) / raw).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: overFraction, end: overFraction),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (_, of, _) {
            final base = 1.0 - of;
            return Row(
              children: [
                Expanded(
                  flex: (base * 1000).round().clamp(1, 1000),
                  child: Container(color: color),
                ),
                Expanded(
                  flex: (of * 1000).round().clamp(1, 1000),
                  child: Container(color: overflowColor),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FtStatGrid extends StatelessWidget {
  const FtStatGrid({super.key, required this.items});

  final List<FtStatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class FtStatItem extends StatelessWidget {
  const FtStatItem({
    super.key,
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: FtColors.ink3,
            fontSize: 10,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color ?? FtColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
