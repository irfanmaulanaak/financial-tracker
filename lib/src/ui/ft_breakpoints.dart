import 'package:flutter/widgets.dart';

/// Material 3 window size classes — single source of truth for any responsive
/// switch (nav rail vs bottom nav, grid columns, max width, dialog vs sheet).
enum FtBreakpoint {
  /// Phones in portrait, narrow web windows. `< 600 dp`.
  compact,

  /// Phones in landscape, small tablets, half-screen web. `< 905 dp`.
  medium,

  /// Tablets, common laptop windows. `< 1240 dp`.
  expanded,

  /// Large laptop / desktop. `>= 1240 dp`.
  large,
}

FtBreakpoint ftBreakpointForWidth(double width) {
  if (width < 600) return FtBreakpoint.compact;
  if (width < 905) return FtBreakpoint.medium;
  if (width < 1240) return FtBreakpoint.expanded;
  return FtBreakpoint.large;
}

extension FtBreakpointContext on BuildContext {
  FtBreakpoint get bp => ftBreakpointForWidth(MediaQuery.sizeOf(this).width);

  bool get isAtLeastMedium => bp.index >= FtBreakpoint.medium.index;
  bool get isAtLeastExpanded => bp.index >= FtBreakpoint.expanded.index;
}
