import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

/// Press-down scale + light haptic. Use for editorial buttons/cards.
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
    final hasInteraction =
        widget.onTap != null || widget.onLongPress != null;
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
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
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
