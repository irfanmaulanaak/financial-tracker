import 'package:flutter/material.dart';

/// Inline name+color-dot chip used on transaction rows when the household
/// has >1 member. Mirrors the small member badge in
/// `claude-design/design/screens-household.jsx`.
class FtMemberChip extends StatelessWidget {
  const FtMemberChip({
    super.key,
    required this.name,
    required this.color,
    this.fontSize = 10,
  });

  final String name;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
