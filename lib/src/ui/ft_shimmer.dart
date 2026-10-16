import 'package:flutter/material.dart';

import '../theme.dart';

/// Skeleton shimmer loader. Shows a shifting gradient over placeholder blocks.
class FtShimmer extends StatefulWidget {
  const FtShimmer({super.key, required this.child});
  final Widget child;

  @override
  State<FtShimmer> createState() => _FtShimmerState();
}

class _FtShimmerState extends State<FtShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool? _disableAnimations;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations != _disableAnimations) {
      _disableAnimations = disableAnimations;
      if (_disableAnimations == true) {
        _ctrl.stop();
      } else {
        _ctrl.repeat();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_disableAnimations == true) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                FtColors.surfaceAlt,
                FtColors.lineStrong,
                FtColors.surfaceAlt,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlideGradientTransform(percent: _ctrl.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform({required this.percent});
  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (percent * 2 - 0.5), 0, 0);
  }
}
