import 'package:flutter/widgets.dart';

import 'ft_breakpoints.dart';

/// Centers and width-constrains screen content on tablet/desktop while
/// remaining full-width on phones. Wrap the body of any top-level screen
/// so the editorial layout reads correctly on wide windows.
///
/// Defaults are tuned for single-column reading: 560 dp on `compact` is
/// effectively no-op (phone widths are usually below 560), then content
/// pins at 560 on medium, 640 on expanded, 720 on large.
class FtPageContainer extends StatelessWidget {
  const FtPageContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;

  /// Override the max width. If null, the breakpoint-driven default is used.
  final double? maxWidth;

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final bp = context.bp;
    final cap = maxWidth ?? _defaultMaxWidth(bp);
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: child,
      ),
    );
  }

  static double _defaultMaxWidth(FtBreakpoint bp) {
    switch (bp) {
      case FtBreakpoint.compact:
        return double.infinity;
      case FtBreakpoint.medium:
        return 560;
      case FtBreakpoint.expanded:
        return 640;
      case FtBreakpoint.large:
        return 720;
    }
  }
}
