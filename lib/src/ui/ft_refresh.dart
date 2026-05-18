import 'package:flutter/material.dart';

import '../theme.dart';
import 'ft_haptics.dart';

/// Project-wide pull-to-refresh wrapper. Brand-colored spinner on the cream
/// surface. The [child] must be a vertically scrollable widget (ListView,
/// CustomScrollView, SingleChildScrollView with AlwaysScrollableScrollPhysics).
///
/// On iOS, uses `RefreshIndicator.adaptive` so the spinner renders as a
/// native Cupertino activity indicator. Fires a light haptic when the user
/// crosses the pull threshold and a success haptic when refresh completes.
class FtRefreshable extends StatefulWidget {
  const FtRefreshable({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<FtRefreshable> createState() => _FtRefreshableState();
}

class _FtRefreshableState extends State<FtRefreshable> {
  bool _hapticArmed = false;

  Future<void> _wrappedRefresh() async {
    _hapticArmed = false;
    try {
      await widget.onRefresh();
      FtHaptics.success();
    } catch (_) {
      FtHaptics.warning();
      rethrow;
    }
  }

  bool _onScroll(ScrollNotification n) {
    // Fire a single tap haptic the moment the user pulls past the threshold;
    // re-arm once the overscroll returns to zero so multi-pull sessions feel
    // tactile without machine-gun haptics during the same drag.
    if (n is OverscrollNotification &&
        n.overscroll < 0 &&
        !_hapticArmed &&
        n.metrics.pixels < -56) {
      _hapticArmed = true;
      FtHaptics.tap();
    } else if (n is ScrollEndNotification && _hapticArmed) {
      _hapticArmed = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: RefreshIndicator.adaptive(
        onRefresh: _wrappedRefresh,
        color: FtColors.ink,
        backgroundColor: FtColors.surface,
        displacement: 56,
        strokeWidth: 2.5,
        child: widget.child,
      ),
    );
  }
}

/// Minimum delay so the spinner stays visible long enough to feel deliberate
/// when the underlying streams resolve almost instantly from Firestore cache.
Future<void> ftRefreshDelay() =>
    Future<void>.delayed(const Duration(milliseconds: 600));
