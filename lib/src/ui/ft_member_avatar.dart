import 'package:flutter/material.dart';

import '../theme.dart';

/// Circular avatar with initials. Used on home header, settings members
/// section, member detail, recent transactions, etc. Mirrors `MemberAvatar`
/// in `claude-design/design/screens-household.jsx`.
class FtMemberAvatar extends StatelessWidget {
  const FtMemberAvatar({
    super.key,
    required this.initials,
    this.color,
    this.size = 28,
    this.ring = false,
    this.pending = false,
  });

  final String initials;
  final Color? color;
  final double size;

  /// Adds a thin outer ring (for the home stack overlap effect).
  final bool ring;

  /// Fades the avatar to indicate a pending invite.
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final c = color ?? FtColors.ink2;
    return Opacity(
      opacity: pending ? 0.55 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: ring ? Border.all(color: FtColors.bg, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: FtColors.bg,
            fontSize: size * 0.42,
            fontFamily: 'Newsreader',
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

/// Overlapping stack of [FtMemberAvatar]s with an optional count chip at the
/// end. Used on the home header to surface household members.
class FtMemberStack extends StatelessWidget {
  const FtMemberStack({
    super.key,
    required this.members,
    this.size = 26,
    this.maxVisible = 3,
    this.onTap,
  });

  final List<FtMemberAvatarData> members;
  final double size;
  final int maxVisible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visible = members.take(maxVisible).toList();
    final extra = members.length - visible.length;
    final step = size * 0.68;
    final slotCount = visible.length + (extra > 0 ? 1 : 0);
    final width = slotCount == 0 ? 0.0 : step * (slotCount - 1) + size;

    final positioned = <Widget>[];
    for (var i = 0; i < visible.length; i++) {
      final m = visible[i];
      positioned.add(Positioned(
        left: step * i,
        child: FtMemberAvatar(
          initials: m.initials,
          color: m.color,
          size: size,
          ring: true,
          pending: m.pending,
        ),
      ));
    }
    if (extra > 0) {
      positioned.add(Positioned(
        left: step * visible.length,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: FtColors.surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(color: FtColors.bg, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            '+$extra',
            style: TextStyle(
              color: FtColors.ink2,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ));
    }
    final stack = SizedBox(
      width: width,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: positioned),
    );
    if (onTap == null) return stack;
    return GestureDetector(onTap: onTap, child: stack);
  }
}

class FtMemberAvatarData {
  const FtMemberAvatarData({
    required this.initials,
    this.color,
    this.pending = false,
  });

  final String initials;
  final Color? color;
  final bool pending;
}
