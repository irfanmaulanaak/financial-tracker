import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 54, 18, 22),
      child: Row(
        children: [
          _ProfileAvatar(displayName: displayName),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_greeting()},',
                  style: const TextStyle(
                    color: FtColors.ink3,
                    fontSize: 11,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  displayName,
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
          _MemberStackPill(members: household.members, onTap: onMembers),
          const SizedBox(width: 8),
          _BellMenu(onSelected: onSelected),
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
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: 14,
              color: FtColors.ink,
              letterSpacing: 0.5,
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
    final stackW = 18.0 + (shown.length - 1) * 14.0;

    return GestureDetector(
      onTap: () {
        FtHaptics.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BellMenu extends StatelessWidget {
  const _BellMenu({required this.onSelected});
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Lainnya',
      iconSize: 18,
      splashRadius: 22,
      offset: const Offset(0, 44),
      icon: const Icon(Icons.notifications_outlined, color: FtColors.ink2),
      onOpened: FtHaptics.select,
      onSelected: onSelected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: FtColors.line, width: 0.5),
      ),
      color: FtColors.surface,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'insights', child: Text('Insight')),
        PopupMenuItem(value: 'goals', child: Text('Tujuan')),
        PopupMenuItem(value: 'investments', child: Text('Investasi')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'accounts', child: Text('Akun')),
        PopupMenuItem(value: 'cards', child: Text('Kartu kredit')),
        PopupMenuItem(value: 'incomes', child: Text('Pemasukan')),
        PopupMenuItem(value: 'categories', child: Text('Kategori')),
        PopupMenuItem(value: 'members', child: Text('Anggota')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'export', child: Text('Ekspor data')),
        PopupMenuItem(value: 'signout', child: Text('Keluar')),
      ],
    );
  }
}
