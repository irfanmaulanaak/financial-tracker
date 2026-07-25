import 'package:flutter/material.dart';

import '../../theme.dart';

/// Shown while Firebase Auth + the user doc are still loading so the user
/// never lands on a half-resolved screen. Pairs with the native splash
/// (same cream background + same logo) so the hand-off is seamless.
///
/// The logo breathes (scale 0.96 ↔ 1.0, opacity 0.85 ↔ 1.0) over a 1.6 s
/// loop so cold launches read as a deliberate reveal instead of a paused
/// spinner. The progress indicator is gone — the breathing itself is the
/// loading affordance.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FtColors.bg,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Image.asset(
              'assets/splash/logo.png',
              width: 128,
              height: 128,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
