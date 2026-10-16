import 'package:flutter/material.dart';

import '../theme.dart';
import 'ft_motion.dart';

/// Dashed-bordered "Tambah X" button rendered at the bottom of management
/// lists (cards, goals, accounts, investments). Matches the pattern from
/// `claude-design/screens-assets.jsx` — full-width, transparent fill, dashed
/// outline, small plus icon + label.
class FtDashedAdd extends StatelessWidget {
  const FtDashedAdd({
    super.key,
    required this.label,
    required this.onTap,
    this.margin,
  });

  final String label;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final wrapped = FtTapScale(
      scale: 0.98,
      onTap: onTap,
      child: DottedBorderBox(
        color: FtColors.lineStrong,
        radius: 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: FtColors.ink2),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: FtColors.ink2,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (margin == null) return wrapped;
    return Padding(padding: margin!, child: wrapped);
  }
}

/// Custom-painted dashed border box, used by [FtDashedAdd] since Flutter
/// has no built-in dashed border support for [Container].
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.child,
    required this.color,
    this.radius = 12,
    this.strokeWidth = 0.8,
    this.dashLength = 5,
    this.gapLength = 4,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics().toList();
    for (final m in metrics) {
      var distance = 0.0;
      while (distance < m.length) {
        final next = (distance + dashLength).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}

/// Small "+" pill used by sub-screens (cards, goals, accounts, etc.) — dark
/// circular button with light icon, matches the design's add affordance.
class FtAddButton extends StatelessWidget {
  const FtAddButton({super.key, required this.onTap, this.tooltip});

  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = FtTapScale(
      scale: 0.9,
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: FtColors.ink, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(Icons.add_rounded, size: 20, color: FtColors.bg),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}
