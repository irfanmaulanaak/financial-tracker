import 'package:flutter/material.dart';

import '../../theme.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import '../household/name_format.dart';

/// Compact avatar + first-name pill — used inline in expense rows and
/// recent-activity lists. Mirrors `MemberChip` from `screens-household.jsx`.
class MemberChip extends StatelessWidget {
  const MemberChip({
    super.key,
    required this.member,
    this.size = 14,
  });

  final Member member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = parseColor(member.color);
    final first = prettyName(member.displayName).split(' ').first;
    return Container(
      padding: EdgeInsets.fromLTRB(3, 2, 7, 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              first.isNotEmpty ? first.characters.first : '?',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Geist',
                fontFeatures: const [FontFeature.tabularFigures()],
                fontSize: size * 0.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            first,
            style: TextStyle(
              color: FtColors.ink2,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
