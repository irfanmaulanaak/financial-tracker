import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../../../ui/ft_motion.dart';
import '../../household/household.dart';
import 'home_formatters.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.household,
    required this.displayName,
    required this.onMembers,
    required this.onSelected,
  });

  final Household household;
  final String displayName;
  final VoidCallback onMembers;
  final ValueChanged<String> onSelected;

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        // Status-bar safe; matches design's 54px on iOS frame.
        topInset > 0 ? topInset + 10 : 24,
        18,
        22,
      ),
      child: Row(
        children: [
          _ProfileAvatar(displayName: displayName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  household.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FtColors.ink3,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_greeting()}, $displayName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                        color: FtColors.ink,
                      ),
                ),
              ],
            ),
          ),
          if (household.members.isNotEmpty) ...[
            _MemberStackPill(members: household.members, onTap: onMembers),
            const SizedBox(width: 8),
          ],
          _OverflowMenu(onSelected: onSelected),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.displayName});
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        shape: BoxShape.circle,
        border: Border.all(color: FtColors.lineStrong, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initialsOf(displayName),
        style: const TextStyle(
          fontFamily: 'Newsreader',
          fontSize: 14,
          color: FtColors.ink,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MemberStackPill extends StatelessWidget {
  const _MemberStackPill({required this.members, required this.onTap});
  final List<Member> members;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final shown = members.take(3).toList();
    final stackW = 22.0 + (shown.length - 1) * 14.0;

    return FtTapScale(
      scale: 0.95,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 9, 4),
        decoration: BoxDecoration(
          color: FtColors.surface,
          border: Border.all(color: FtColors.line, width: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: stackW,
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = 0; i < shown.length; i++)
                    Positioned(
                      left: i * 14.0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: parseColor(shown[i].color),
                          shape: BoxShape.circle,
                          border: Border.all(color: FtColors.bg, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initialsOf(shown[i].displayName).characters.first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${members.length}',
              style: const TextStyle(
                color: FtColors.ink3,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile / overflow menu. Items kept short — most actions moved to bottom nav
/// or the central "+" chooser.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({required this.onSelected});
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Menu',
      iconSize: 20,
      splashRadius: 22,
      offset: const Offset(0, 46),
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: FtColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: FtColors.line, width: 0.5),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.more_horiz_rounded,
          color: FtColors.ink2,
          size: 18,
        ),
      ),
      onOpened: FtHaptics.select,
      onSelected: onSelected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: FtColors.line, width: 0.5),
      ),
      color: FtColors.surface,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'insights',
          child: _MenuRow(
              icon: Icons.insights_rounded, label: 'Kesehatan Finansial'),
        ),
        PopupMenuItem(
          value: 'categories',
          child: _MenuRow(icon: Icons.category_rounded, label: 'Kategori'),
        ),
        PopupMenuItem(
          value: 'members',
          child: _MenuRow(icon: Icons.group_rounded, label: 'Anggota'),
        ),
        PopupMenuItem(
          value: 'export',
          child: _MenuRow(icon: Icons.ios_share_rounded, label: 'Ekspor data'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'signout',
          child: _MenuRow(
            icon: Icons.logout_rounded,
            label: 'Keluar akun',
            danger: true,
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? FtColors.danger : FtColors.ink2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 13),
        ),
      ],
    );
  }
}
