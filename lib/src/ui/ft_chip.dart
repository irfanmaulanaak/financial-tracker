import 'package:flutter/material.dart';

import '../theme.dart';

/// Inline status/tag chip. `soft` renders a tinted background + colored text;
/// solid renders the full color background. Mirrors `Chip` in
/// `claude-design/design/widgets.jsx`.
class FtChip extends StatelessWidget {
  const FtChip({
    super.key,
    required this.label,
    this.color,
    this.soft = true,
    this.icon,
    this.fontSize = 10.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  });

  final String label;
  final Color? color;
  final bool soft;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final base = color ?? FtColors.ink;
    final bg = soft ? base.withValues(alpha: 0.14) : base;
    final fg = soft ? base : FtColors.bg;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
