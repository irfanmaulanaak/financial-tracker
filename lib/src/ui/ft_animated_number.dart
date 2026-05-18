import 'package:flutter/widgets.dart';

/// Tweens between an old and new integer value (480ms ease-out), running the
/// caller's `formatter` on each interpolated frame so currency totals "count
/// up" smoothly when balances change.
///
/// Use sparingly — meant for hero numbers (net worth, monthly total, card
/// available limit). Don't wrap every number in a list with this; it costs
/// a frame builder per tick.
class FtAnimatedNumber extends StatelessWidget {
  const FtAnimatedNumber({
    super.key,
    required this.value,
    required this.formatter,
    this.duration = const Duration(milliseconds: 480),
    this.style,
    this.maxLines = 1,
    this.textAlign,
  });

  final int value;
  final String Function(int value) formatter;
  final Duration duration;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(
        formatter(value),
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: value.toDouble(), end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) {
        return Text(
          formatter(v.round()),
          style: style,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
        );
      },
    );
  }
}
