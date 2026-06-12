import 'package:flutter/widgets.dart';

import '../theme.dart';
import 'ft_ui.dart' show FtShimmer;

/// Composable shape primitives for shimmer-skeleton placeholders. Use these
/// to mirror the shape of upcoming content (a list with N tiles, a card
/// with a header and two lines, etc.) so the load → data transition reads
/// as the same page reflowing instead of two unrelated views.
///
/// Always wrap the assembled skeleton tree in a single `FtShimmer` at the
/// top — the gradient shader needs a stable subtree.

class FtSkeletonLine extends StatelessWidget {
  const FtSkeletonLine({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 4,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class FtSkeletonCircle extends StatelessWidget {
  const FtSkeletonCircle({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Pre-shaped row silhouette matching the standard FtCard tile pattern:
/// `[circle] [two stacked lines] [trailing amount line]`. Drop into a
/// Column to fake the list while data resolves.
class FtSkeletonTile extends StatelessWidget {
  const FtSkeletonTile({
    super.key,
    this.height = 72,
    this.margin = const EdgeInsets.fromLTRB(22, 0, 22, 10),
    this.padding = const EdgeInsets.all(14),
  });

  final double height;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: FtColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        child: Row(
          children: [
            const FtSkeletonCircle(size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FtSkeletonLine(width: 140, height: 12),
                  const SizedBox(height: 6),
                  FtSkeletonLine(width: 100, height: 10),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FtSkeletonLine(width: 56, height: 12),
          ],
        ),
      ),
    );
  }
}

/// Drop-in column of [FtSkeletonTile]s, wrapped in a single [FtShimmer] so
/// the whole subtree animates together. Use as the `loading` placeholder for
/// list screens (expenses, incomes, cards, goals, etc.).
class FtSkeletonListView extends StatelessWidget {
  const FtSkeletonListView({
    super.key,
    this.count = 6,
    this.padding = const EdgeInsets.only(top: 6, bottom: 120),
    this.tileHeight = 72,
  });

  final int count;
  final EdgeInsetsGeometry padding;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    return FtShimmer(
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            for (var i = 0; i < count; i++)
              FtSkeletonTile(height: tileHeight),
          ],
        ),
      ),
    );
  }
}
