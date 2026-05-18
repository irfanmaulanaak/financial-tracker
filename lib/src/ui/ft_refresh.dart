import 'package:flutter/material.dart';

import '../theme.dart';

/// Project-wide pull-to-refresh wrapper. Brand-colored spinner on the cream
/// surface. The [child] must be a vertically scrollable widget (ListView,
/// CustomScrollView, SingleChildScrollView with AlwaysScrollableScrollPhysics).
///
/// [onRefresh] should invalidate the relevant Riverpod stream providers and
/// await long enough for the spinner to feel responsive (~600ms).
class FtRefreshable extends StatelessWidget {
  const FtRefreshable({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: FtColors.ink,
      backgroundColor: FtColors.surface,
      displacement: 56,
      strokeWidth: 2.5,
      child: child,
    );
  }
}

/// Minimum delay so the spinner stays visible long enough to feel deliberate
/// when the underlying streams resolve almost instantly from Firestore cache.
Future<void> ftRefreshDelay() =>
    Future<void>.delayed(const Duration(milliseconds: 600));
