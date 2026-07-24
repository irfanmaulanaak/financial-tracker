import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import 'ft_haptics.dart';

/// Entry animation: fades + translates up. Matches the design's `ft-fadeup`.
class FtFadeUp extends StatefulWidget {
  const FtFadeUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.delay = Duration.zero,
    this.distance = 8.0,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final double distance;

  @override
  State<FtFadeUp> createState() => _FtFadeUpState();
}

class _FtFadeUpState extends State<FtFadeUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.distance),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Press-down scale + light haptic for buttons and tappable surfaces.
class FtTapScale extends StatefulWidget {
  const FtTapScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;

  @override
  State<FtTapScale> createState() => _FtTapScaleState();
}

class _FtTapScaleState extends State<FtTapScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final hasInteraction = widget.onTap != null || widget.onLongPress != null;
    if (!hasInteraction) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) {
        _set(false);
        if (widget.onTap != null) {
          if (widget.haptic) FtHaptics.tap();
          widget.onTap!();
        }
      },
      onTapCancel: () => _set(false),
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) FtHaptics.warning();
              widget.onLongPress!();
            },
      child: _pressEffect(context),
    );
  }

  Widget _pressEffect(BuildContext context) {
    final jelly = FtColors.liquid && !MediaQuery.disableAnimationsOf(context);
    if (!jelly) {
      return AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 140),
        // Slight overshoot on release for an iOS-like spring feel.
        curve: const Cubic(0.34, 1.36, 0.64, 1),
        child: widget.child,
      );
    }
    // Liquid controls react immediately, then settle without a cartoon bounce.
    // The small vertical compression gives glass a soft, gel-like response.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _down ? 1.0 : 0.0),
      duration: Duration(milliseconds: _down ? 80 : 220),
      curve: _down ? Curves.easeOut : const Cubic(0.2, 0.8, 0.2, 1),
      builder: (_, p, child) {
        final sx = lerpDouble(1, widget.scale * 1.01, p)!;
        final sy = lerpDouble(1, widget.scale * 0.99, p)!;
        return Transform(
          transform: Matrix4.diagonal3Values(sx, sy, 1),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Cross-fade + slide page transition for go_router (use as
/// `pageBuilder: (c, s) => ftFadeUpPage(c, s, child: ...)`).
Page<T> ftFadeUpPage<T>(
  BuildContext context,
  GoRouterState state, {
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, _, w) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curve),
          child: w,
        ),
      );
    },
  );
}

/// Drill-in transition for detail screens. Fades + scales the destination
/// from 0.96 → 1.0 over 280ms, giving navigation a "zoom into" feel that
/// reads as distinct from the lateral fade-up used for top-level routes.
Page<T> ftScaleUpPage<T>(
  BuildContext context,
  GoRouterState state, {
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, _, w) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(curve),
          child: w,
        ),
      );
    },
  );
}

/// Modal-style transition for record/new routes (compose-an-expense, etc.).
/// Slides up from 8% below + fades; matches the iOS "present modally" feel.
Page<T> ftBottomSlidePage<T>(
  BuildContext context,
  GoRouterState state, {
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (_, animation, _, w) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curve),
          child: w,
        ),
      );
    },
  );
}

/// Staggered fade-up for list items. Wraps a list item's child with a
/// per-index delay so items cascade into view instead of popping at once.
///
/// The first `maxStaggered` items are delayed by `index * perItemDelay`;
/// items past that index animate without delay (so long lists don't make
/// the user wait for the tail to finish).
///
/// Honors `MediaQuery.disableAnimations` (accessibility) by skipping the
/// reveal entirely when the OS requests reduced motion.
class FtListReveal extends StatelessWidget {
  const FtListReveal({
    super.key,
    required this.index,
    required this.child,
    this.perItemDelay = const Duration(milliseconds: 45),
    this.maxStaggered = 8,
    this.distance = 6.0,
    this.duration = const Duration(milliseconds: 280),
  });

  final int index;
  final Widget child;
  final Duration perItemDelay;
  final int maxStaggered;
  final double distance;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final clampedIndex = index < maxStaggered ? index : maxStaggered;
    final delay = perItemDelay * clampedIndex;
    return FtFadeUp(
      delay: delay,
      duration: duration,
      distance: distance,
      child: child,
    );
  }
}
