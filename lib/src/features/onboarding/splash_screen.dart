import 'package:flutter/material.dart';

import '../../theme.dart';

/// Shown while Firebase Auth + the user doc are still loading so the user
/// never lands on a half-resolved screen. Pairs with the native splash
/// (same cream background + same logo) so the hand-off is seamless.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FtColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/splash/logo.png',
              width: 112,
              height: 112,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: FtColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
