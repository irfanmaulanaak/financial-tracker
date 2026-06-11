import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import 'ft_breakpoints.dart';
import 'ft_haptics.dart';
import 'ft_motion.dart';
import 'ft_ui.dart' show FtTab;

/// Wide-screen counterpart to `FtBottomNav` — vertical side rail with the
/// same five destinations. Used by `FtAppChrome` on `medium`+ breakpoints.
class FtSideNav extends StatelessWidget {
  const FtSideNav({super.key, required this.current});

  final FtTab current;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _SideItem(FtTab.home, Icons.home_rounded, Icons.home_outlined,
          'Beranda', '/home'),
      _SideItem(FtTab.spend, Icons.donut_large_rounded,
          Icons.donut_large_outlined, 'Pengeluaran', '/spend'),
      _SideItem(FtTab.assets, Icons.pie_chart_rounded,
          Icons.pie_chart_outline_rounded, 'Aset', '/accounts'),
      _SideItem(FtTab.goals, Icons.flag_rounded, Icons.flag_outlined,
          'Tujuan', '/goals'),
      _SideItem(FtTab.cards, Icons.credit_card_rounded,
          Icons.credit_card_outlined, 'Utang', '/cards'),
    ];

    final extended = context.isAtLeastExpanded;
    return SafeArea(
      right: false,
      child: Container(
        // 96 fits the longest label ("Pengeluaran") at 9.5px without
        // ellipsis; 84 truncated it to "Pengeluar…".
        width: extended ? 200 : 96,
        margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: FtColors.surface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: FtColors.lineStrong, width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: _SideButton(
                  item: item,
                  active: current == item.tab,
                  extended: extended,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.item,
    required this.active,
    required this.extended,
  });

  final _SideItem item;
  final bool active;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.96,
      haptic: false,
      onTap: active
          ? null
          : () {
              FtHaptics.select();
              context.go(item.path);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 10,
          horizontal: extended ? 14 : 4,
        ),
        decoration: BoxDecoration(
          color: active ? FtColors.bg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: extended
            ? Row(
                children: [
                  Icon(
                    active ? item.iconActive : item.icon,
                    size: 20,
                    color: active ? FtColors.ink : FtColors.ink3,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? FtColors.ink : FtColors.ink3,
                        fontSize: 13,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(
                    active ? item.iconActive : item.icon,
                    size: 22,
                    color: active ? FtColors.ink : FtColors.ink3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? FtColors.ink : FtColors.ink3,
                      fontSize: 9.5,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SideItem {
  const _SideItem(
    this.tab,
    this.iconActive,
    this.icon,
    this.label,
    this.path,
  );

  final FtTab tab;
  final IconData iconActive;
  final IconData icon;
  final String label;
  final String path;
}
