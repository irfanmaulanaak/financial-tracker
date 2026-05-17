import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// iOS-style backdrop-blur pill. Used for nav buttons and floating chrome
/// where we want a "liquid glass" feel. Mirrors `IOSGlassPill` in
/// `claude-design/design/ios-frame.jsx`.
class FtGlassPill extends StatelessWidget {
  const FtGlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.radius = 999,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: FtColors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: FtColors.lineStrong, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return pill;
    return GestureDetector(onTap: onTap, child: pill);
  }
}
