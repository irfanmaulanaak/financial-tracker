import 'package:flutter/material.dart';

import '../../theme.dart';

/// Shown while Firebase Auth + the user doc are still loading so the user
/// never lands on a half-resolved screen. Pairs with the native splash
/// (same cream background) so the hand-off is seamless.
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
            Text(
              'FinSist',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pengatur keuangan keluarga',
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 12,
              ),
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
